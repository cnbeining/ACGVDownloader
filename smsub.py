#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import re
import xml.dom.minidom
import ctypes
import os.path
import operator
import copy
import optparse
import codecs, locale
import traceback

def find_if(pred, it):
    for i in it:
        if pred(i): return i
    return None

class Color(object):
    def __init__(self, *a):
        if len(a) == 3:
            self._r = a[0]
            self._g = a[1]
            self._b = a[2]
        elif len(a) == 1:
            self._r = (a[0]>>16) & 0xFF
            self._g = (a[0]>>8) & 0xFF
            self._b = a[0] & 0xFF
        else:
            raise ValueError('Color() takes 1 or 3 arguments')
    def r(self): return self._r
    def g(self): return self._g
    def b(self): return self._b
    def asTuple(self):
        return (self._r, self._g, self._b)
    def asIntRgb(self):
        return (self._r<<16) | (self._g<<8) | self._b
    def asIntBgr(self):
        return (self._b<<16) | (self._g<<8) | self._r
    def __eq__(self, that):
        return self._r == that._r and self._g == that._g and self._b == that._b
    def __ne__(self, that):
        return not self.__eq__(that)
    def __hash__(self):
        return self.asIntRgb()
    def __str__(self):
        return str(self.asTuple())
    def __repr__(self):
        return 'Color(%d, %d, %d)' % (self._r, self._g, self._b)

class SsaStyle(object):
    def __init__(self, fontFace, fontSize, color):
        self._fontFace = fontFace
        self._fontSize = fontSize
        self._color = color
    def fontFace(self): return self._fontFace
    def fontSize(self): return self._fontSize
    def color(self): return self._color
    def __eq__(self, that):
        return self._fontFace == that._fontFace and \
               self._fontSize == that._fontSize and \
               self._color == that._color
    def __ne__(self, that):
        return not self.__eq__(that)
    def __hash__(self):
        h = 17
        h = 31*h + hash(self._fontFace)
        h = 31*h + self._fontSize
        h = 31*h + hash(self._color)
        return h
    def __str__(self):
        return '(%r, %d, %s)' % (self._fontFace, self._fontSize, self._color)
    def __repr__(self):
        return 'SsaStyle(%r, %d, %r)' % (self._fontFace, self._fontSize, self._color)

class SsaDialogue(object):
    def __init__(self, text, time_, duration, style):
        self._text = text
        self._time = time_
        self._duration = duration
        self._style = style
    def text(self): return self._text
    def timeStart(self): return self._time
    def timeEnd(self): return self._time + self._duration
    def duration(self): return self._duration
    def style(self): return self._style
    def __str__(self):
        return '(%r, %d, %d, %s)' % (
            self._text, self._time, self._duration, self._style
        )
    def __repr__(self):
        return 'SsaDialogue(%r, %d, %d, %r)' % (
            self._text, self._time, self._duration, self._style
        )

SSA_TIME_MAX = 10*60*60*1000 - 1
SSA_TIME_RE = re.compile(r'^(\d):(\d\d):(\d\d).(\d\d)$')

def ssa_time2str(t):
    if t < 0: raise ValueError('argument must not be negative')
    if t > SSA_TIME_MAX: raise ValueError('argument exceeds SSA_TIME_MAX')
    h = t / (60*60*1000)
    t -= h * (60*60*1000)
    m = t / (60*1000)
    t -= m * (60*1000)
    s = t / 1000
    t -= s * 1000
    ms = t
    return '%d:%02d:%02d.%02d' % (h, m, s, ms/10)

def ssa_str2time(str_):
    match = SSA_TIME_RE.search(str_)
    if not match: raise ValueError('invalid format')
    h, m, s, cs = map(int, match.groups())
    if m > 59 or s > 59: raise ValueError('minute or second exceeds 59')
    return h*(60*60*1000) + m*(60*1000) + s*1000 + cs*10

class NicoCmd(object):
    _FONT_SIZES = tuple(xrange(3))
    FONT_SIZE_SMALL, FONT_SIZE_MEDIUM, FONT_SIZE_BIG = _FONT_SIZES
    _NAME_FONT_SIZE = dict(
        small  = FONT_SIZE_SMALL,
        medium = FONT_SIZE_MEDIUM,
        big    = FONT_SIZE_BIG,
    )
    _NAME_COLOR = dict(
        black   = Color(0x000000),
        red     = Color(0xFF0000),
        green   = Color(0x00FF00),
        yellow  = Color(0xFFFF00),
        blue    = Color(0x0000FF),
        purple  = Color(0xC000FF),
        cyan    = Color(0x00FFFF),
        white   = Color(0xFFFFFF),
        orange  = Color(0xFFC000),
        pink    = Color(0xFF8080),
        black2  = Color(0x666666),
        red2    = Color(0xCC0033), truered        = Color(0xCC0033),
        green2  = Color(0x00CC66), elementalgreen = Color(0x00CC66),
        yellow2 = Color(0x999900), madyellow      = Color(0x999900),
        blue2   = Color(0x3399FF), marineblue     = Color(0x3399FF),
        purple2 = Color(0x6633CC), nobleviolet    = Color(0x6633CC),
        cyan2   = Color(0x00CCCC),
        white2  = Color(0xCCCC99), niconicowhite  = Color(0xCCCC99),
        orange2 = Color(0xFF6600), passionorange  = Color(0xFF6600),
        pink2   = Color(0xFF33CC),
    )
    _RE_FONT_SIZE = re.compile(ur'^(%s)$' % u'|'.join(_NAME_FONT_SIZE.iterkeys()))
    _RE_COLOR = re.compile(ur'^(?:#([0-9a-fA-F]{6}))|(%s)$' % u'|'.join(_NAME_COLOR.iterkeys()))
    _RE_DURATION = re.compile(ur'^@([0-9]+)$')
    @staticmethod
    def parse(text, cmd_def):
        cmd_dict = dict(
            fontSize=cmd_def.fontSize(),
            color=cmd_def.color(),
            duration=cmd_def.duration()
        )
        for t in reversed(text.split()):
            NicoCmd._parseCmd(t, cmd_dict)
        return NicoCmd(cmd_dict['fontSize'], cmd_dict['color'], cmd_dict['duration'])
    @staticmethod
    def parseFontSize(text):
        text = text.lower()
        match = NicoCmd._RE_FONT_SIZE.search(text)
        if not match: return None
        return NicoCmd._NAME_FONT_SIZE[match.group(1)]
    @staticmethod
    def parseColor(text):
        text = text.lower()
        match = NicoCmd._RE_COLOR.search(text)
        if not match: return None
        if match.group(1):
            return Color(int(match.group(1), 16))
        else:
            return NicoCmd._NAME_COLOR[match.group(2)]
    @staticmethod
    def parseDuration(text):
        text = text.lower()
        match = NicoCmd._RE_DURATION.search(text)
        if not match: return None
        return 1000 * int(match.group(1))
    @staticmethod
    def _parseCmd(text, cmd_dict):
        text = text.lower()
        v = NicoCmd.parseFontSize(text)
        if v:
            cmd_dict['fontSize'] = v
            return
        v = NicoCmd.parseColor(text)
        if v:
            cmd_dict['color'] = v
            return
        v = NicoCmd.parseDuration(text)
        if v:
            cmd_dict['duration'] = v
            return
    def __init__(self, fontSize, color, duration):
        if fontSize not in NicoCmd._FONT_SIZES:
            raise ValueError('fontSize must be %d-%d' % (NicoCmd._FONT_SIZES[0], NicoCmd._FONT_SIZES[-1]))
        self._fontSize = fontSize
        self._color = color
        self._duration = duration
    def fontSize(self): return self._fontSize
    def color(self): return self._color
    def duration(self): return self._duration
    def __str__(self):
        return '(%d, %s, %d)' % (self._fontSize, self._color, self._duration)
    def __repr__(self):
        return 'NicoCmd(%d, %r, %d)' % (self._fontSize, self._color, self._duration)

class NicoComment(object):
    _RE_NIWANGO = re.compile(ur'^/\s*[a-zA-Z_]')
    def __init__(self, text, time_, cmd, byAuthor):
        self._text = text
        self._time = time_
        self._cmd = cmd
        self._byAuthor = byAuthor
    def text(self): return self._text
    def time(self): return self._time
    def cmd(self): return self._cmd
    def byAuthor(self): return self._byAuthor
    def isNiwango(self):
        return self._byAuthor and NicoComment._RE_NIWANGO.search(self._text)
    def __str__(self):
        return '(%r, %d, %s, %s)' % (self._text, self._time, self._cmd, self._byAuthor)
    def __repr__(self):
        return 'NicoComment(%r, %d, %r, %s)' % (self._text, self._time, self._cmd, self._byAuthor)

mediainfo = None

def mediainfo_load(path):
    global mediainfo
    try:
        mediainfo = ctypes.cdll.LoadLibrary(path)
        mediainfo.MediaInfo_Option.restype = ctypes.c_wchar_p
        mediainfo.MediaInfo_Option.argtypes = (ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_wchar_p)
        mediainfo.MediaInfo_New.restype = ctypes.c_void_p
        mediainfo.MediaInfo_Open.argtypes = (ctypes.c_void_p, ctypes.c_wchar_p)
        mediainfo.MediaInfo_Inform.restype = ctypes.c_wchar_p
        mediainfo.MediaInfo_Inform.argtypes = (ctypes.c_void_p, ctypes.c_uint32)
        mediainfo.MediaInfo_Close.argtypes = (ctypes.c_void_p,)
        mediainfo.MediaInfo_Delete.argtypes = (ctypes.c_void_p,)
    except OSError:
        mediainfo = None

FONT_FACE_DEF = u'MS UI Gothic'
FONT_SIZE_DEF = 16
COLOR_DEF = Color(0xFFFFFF)
DURATION_DEF = 3000

ENC_LOCALE = locale.getpreferredencoding()
ENC_FS = sys.getfilesystemencoding()
ENC_SSA = 'utf-16-be'
ENC_SSA_BOM = codecs.BOM_UTF16_BE
ENC_NICO = 'utf-8'

NEWLINE_SSA = '\x0D\x0A'

FORK_AUTHOR = 1

MEDIAINFO_DLL = 'mediainfo.dll'

EXT_SSA = '.ssa'
EXTS_VIDEO = ('.mp4', '.flv')

sys.stdout = codecs.getwriter(ENC_LOCALE)(sys.stdout, errors='replace')
sys.stderr = codecs.getwriter(ENC_LOCALE)(sys.stderr, errors='replace')

write = sys.stdout.write

def read_comments(in_, cmd_def):
    comments = []
    doc = xml.dom.minidom.parse(in_)
    for chat in doc.getElementsByTagName('chat'):
        text = chat.firstChild.data.strip()
        time_ = 10 * int(chat.getAttribute('vpos').strip())
        cmd = NicoCmd.parse(chat.getAttribute('mail').strip(), cmd_def)
        by_author = chat.hasAttribute('fork') and int(chat.getAttribute('fork')) == FORK_AUTHOR
        comments.append(NicoComment(text, time_, cmd, by_author))
    doc.unlink()
    return comments

def write_dialogues(out, dialogues, style_num, size, opts):
    out.write(ENC_SSA_BOM)
    out = codecs.getwriter(ENC_SSA)(out)
    out.write(u'''\
[Script Info]
ScriptType: v4.00
Collisions: Normal
Timer: 100.0000
PlayDepth: 0
'''.replace(u'\n', NEWLINE_SSA))
    width, height = size if size else (opts.width, opts.height)
    if width and height:
        out.write(u'''\
PlayResX: %d
PlayResY: %d
'''.replace(u'\n', NEWLINE_SSA) % (width, height))
    out.write(u'''\

[v4 Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding
Style: Default,Arial,16,16777215,16777215,16777215,0,0,0,1,1,1,2,30,30,15,0,0
'''.replace(u'\n', NEWLINE_SSA))
    for style, n in sorted(style_num.iteritems(), key=operator.itemgetter(1)):
        out.write(u'Style: S%d,%s,%d,%d,%d,%d,0,-1,0,1,1,1,2,30,30,0,0,0' % (
            n, style.fontFace(), style.fontSize(),
            style.color().asIntBgr(), style.color().asIntBgr(), style.color().asIntBgr()
        ))
        out.write(NEWLINE_SSA)
    out.write(u'''\

[Events]
Format: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''.replace(u'\n', NEWLINE_SSA))
    for dia in dialogues:
        out.write(u'Dialogue: Marked=0,%s,%s,S%d,,0000,0000,0000,,%s' % (
            ssa_time2str(dia.timeStart()), ssa_time2str(dia.timeEnd()),
            style_num[dia.style()], dia.text()
        ))
        out.write(NEWLINE_SSA)

def detect_size(root, mih):
    RE_SIZE = re.compile(ur'^(\d+)x(\d+)$')
    ext = find_if(lambda x: os.path.isfile(root+x), EXTS_VIDEO)
    if not ext: return None
    path_video = root + ext
    size = None
    if mediainfo.MediaInfo_Open(mih, path_video):
        mediainfo.MediaInfo_Option(mih, 'Inform', 'Video;%Width%x%Height%')
        size_str = mediainfo.MediaInfo_Inform(mih, -1)
        mediainfo.MediaInfo_Close(mih)
        match = RE_SIZE.search(size_str)
        if match:
            size = tuple(map(int, match.groups()))
    return size

def smsub(path_xml, opts, mih):
    style_num = {}
    with open(path_xml, 'rU') as in_:
        comments = read_comments(in_, NicoCmd(NicoCmd.FONT_SIZE_MEDIUM, opts.color, opts.duration))
    dialogues = []
    n_style = 0
    for comment in comments:
        # 空コメントとニワン語は捨てる
        if not comment.text(): continue
        if comment.isNiwango(): continue
        style = SsaStyle(
            opts.fontFace,
            opts.fontSize[comment.cmd().fontSize()],
            comment.cmd().color()
        )
        if style not in style_num:
            style_num[style] = n_style
            n_style += 1
        dialogues.append(SsaDialogue(
            comment.text(), comment.time(), comment.cmd().duration(), style
        ))
    root, _ = os.path.splitext(path_xml)
    path_ssa = root + EXT_SSA
    size = detect_size(root, mih) if mih else None
    with open(path_ssa, 'wb') as out:
        write_dialogues(out, dialogues, style_num, size, opts)
    write(u'%s\n' % path_ssa)

def error(*a):
    sys.exit(a[0] if a else 1)

def warn(s):
    sys.stderr.write(s)
    sys.stderr.write('\n')

def parse_args():
    def chk_unistring(option, opt, value):
        try:
            return unicode(value, encoding=ENC_LOCALE)
        except UnicodeDecodeError:
            raise optparse.OptionValueError('option %s: can\'t decode to unicode: %r' % (opt, value))
    def chk_color(option, opt, value):
        color = NicoCmd.parseColor(value)
        if not color:
            raise optparse.OptionValueError('option %s: invalid color string: %r' % (opt, value))
        return color
    class MyOption(optparse.Option):
        TYPES = optparse.Option.TYPES + ('unistring', 'color')
        TYPE_CHECKER = copy.copy(optparse.Option.TYPE_CHECKER)
        TYPE_CHECKER['unistring'] = chk_unistring
        TYPE_CHECKER['color'] = chk_color
    opp = optparse.OptionParser(option_class=MyOption,
                                usage='%prog [options] <comment_xml> ...')
    opp.add_option('--width', action='store', type='int',
                   dest='width',
                   help='default video width\t[default: %default]')
    opp.add_option('--height', action='store', type='int',
                   dest='height',
                   help='default video height\t[default: %default]')
    opp.add_option('--font-face', action='store', type='unistring',
                   dest='fontFace',
                   help='font face\t[default: %default]')
    opp.add_option('--font-size-small', action='store', type='int',
                   dest='fontSizeSmall',
                   help='small font size\t[default: %default]')
    opp.add_option('--font-size-medium', action='store', type='int',
                   dest='fontSizeMedium',
                   help='medium font size\t[default: %default]')
    opp.add_option('--font-size-big', action='store', type='int',
                   dest='fontSizeBig',
                   help='big font size\t[default: %default]')
    opp.add_option('--color', action='store', type='color',
                   dest='color',
                   help='default color (#rrggbb)\t[default: %default]')
    opp.add_option('--duration', action='store', type='int',
                   dest='duration',
                   help='default display duration (ms)\t[default: %default]')
    opp.set_defaults(
        width=None, height=None,
        fontFace='MS UI Gothic', # str 型なので自動的に unicode へ変換される
        fontSizeSmall=14,
        fontSizeMedium=16,
        fontSizeBig=18,
        color=Color(0xFFFFFF),
        duration=3000
    )
    opts, args = opp.parse_args()
    opts.fontSize = {
        NicoCmd.FONT_SIZE_SMALL : opts.fontSizeSmall,
        NicoCmd.FONT_SIZE_MEDIUM : opts.fontSizeMedium,
        NicoCmd.FONT_SIZE_BIG : opts.fontSizeBig,
    }
    if not args:
        opp.print_help()
        error()
    if (opts.width is not None and opts.width <= 0) or \
       (opts.height is not None and opts.height <= 0):
        error('--width and --height must be positive')
    if any(map(lambda n: n <= 0, opts.fontSize.itervalues())):
        error('--font-size-* must be positive')
    if opts.duration <= 0:
        error('--duration must be positive')
    return opts, args

def main():
    global mediainfo
    EXC_FATAL = (SystemExit, KeyboardInterrupt, MemoryError)
    opts, args = parse_args()
    mediainfo_load(MEDIAINFO_DLL)
    if mediainfo:
        mediainfo.MediaInfo_Option(0, 'Internet', 'No')
        mih = mediainfo.MediaInfo_New()
    else:
        mih = None
    for path in map(lambda x: unicode(x, encoding=ENC_FS), args):
        try:
            smsub(path, opts, mih)
        except EXC_FATAL:
            raise
        except Exception:
            warn(u'[FAILED] %s' % path)
            traceback.print_exc()
            warn('')
        except:
            warn(u'[FAILED] %s: UNKNOWN EXCEPTION' % path)
            traceback.print_exc()
            warn('')
    if mih:
        mediainfo.MediaInfo_Delete(mih)

if __name__ == '__main__': main()
