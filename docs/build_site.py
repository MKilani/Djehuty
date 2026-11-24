import html, os
RAW = "https://github.com/MKilani/Djehuty/raw/master/imagesReadme/"
BLOB = "https://github.com/MKilani/Djehuty/blob/master/"
OUT = os.path.dirname(os.path.abspath(__file__))

PAGES = [
    ("index.html", "Overview"),
    ("why-unicode.html", "Why Unicode?"),
    ("typing.html", "Typing reference"),
    ("quadrats.html", "Quadrats and ligatures"),
    ("breaking.html", "Breaking characters"),
    ("font.html", "The font"),
    ("examples.html", "Examples and citation"),
    ("feedback.html", "Feedback"),
]

def menu(current):
    links = []
    for href, label in PAGES:
        cur = ' aria-current="page"' if href == current else ""
        links.append(f'      <a href="{href}"{cur}>{label}</a>')
    return "\n".join(links)

def page(current, title, body):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)} · Djehuty</title>
<meta name="description" content="Djehuty: a Unicode font and input method for ancient Egyptian hieroglyphs.">
<link rel="stylesheet" href="style.css">
</head>
<body>
<div class="shell">
<aside>
  <p class="brand">Djehuty</p>
  <p class="brand-sub">Unicode hieroglyphs · font and input method</p>
  <nav class="menu" aria-label="Site">
{menu(current)}
  </nav>
  <p class="aside-foot">Marwan Kilani<br>Freie Universität Berlin<br>Swiss National Science Foundation</p>
</aside>
<main>
<div class="wrap">
{body}
<footer>Djehuty is an on-going project by Marwan Kilani, Freie Universität Berlin, supported by the Swiss National Science Foundation. Repository: <a href="https://github.com/MKilani/Djehuty">github.com/MKilani/Djehuty</a></footer>
</div>
</main>
</div>
</body>
</html>
"""


ICONS = {
  "keyboard": '<rect x="2" y="6" width="20" height="12" rx="2"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M7 14h10"/>',
  "search": '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/>',
  "doc": '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/>',
  "layers": '<path d="M12 3 2 8l10 5 10-5z"/><path d="m2 13 10 5 10-5"/>',
  "list": '<path d="M9 6h11M9 12h11M9 18h11"/><path d="M4 6h.01M4 12h.01M4 18h.01"/>',
  "unlink": '<path d="M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-1 1"/><path d="M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l1-1"/>',
  "download": '<path d="M12 3v12m0 0-4-4m4 4 4-4"/><path d="M4 17v3h16v-3"/>',
  "check": '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
  "gear": '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/>',
  "info": '<circle cx="12" cy="12" r="9"/><path d="M12 16v-5M12 8h.01"/>',
  "learn": '<path d="M9 18h6M10 21h4"/><path d="M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z"/>',
}
def icon(name):
    return f'<span class="ic-wrap" aria-hidden="true"><svg class="ic" viewBox="0 0 24 24">{ICONS[name]}</svg></span>'

def fig(name, caption, alt):
    return f'<figure><img src="{RAW}{name}" alt="{html.escape(alt)}"><figcaption>{html.escape(caption)}</figcaption></figure>'

P = {}

P["index.html"] = ("Djehuty", f"""
<h1>Djehuty</h1>
<p class="lede">Type Egyptian hieroglyphs in any program, as ordinary Unicode text.</p>
<div class="btns">
  <a class="btn primary" href="https://github.com/MKilani/Djehuty/releases">Download for macOS</a>
  <a class="btn" href="why-unicode.html">Why Unicode?</a>
</div>

<div class="video">
  <!-- Add the demonstration video as how-it-works.mp4 next to this page. -->
  <video controls preload="metadata" aria-label="How Djehuty works">
    <source src="how-it-works.mp4" type="video/mp4">
    Your browser does not support embedded video.
  </video>
  <p class="caption">How Djehuty works: a short demonstration.</p>
</div>

<h2 id="what">What it is</h2>
<p class="lede-line">Djehuty is an input method for macOS. It takes the letters you type, shows a list of matching words or strings in hieroglyphs, and inserts the one you choose.</p>
<div class="tiles">
  <div class="tile">{icon("keyboard")}<h3>Any program</h3><p>Works in any text field: editors, word processors, emails, browsers, databases and online forms.</p></div>
  <div class="tile">{icon("search")}<h3>Searchable</h3><p>Hieroglyphs are characters. They can be searched, copied and sorted like any other text.</p></div>
  <div class="tile">{icon("doc")}<h3>Exportable</h3><p>The text can be exported, for example to PDF, and stays searchable.</p></div>
  <div class="tile">{icon("layers")}<h3>Two parts</h3><p>The EgyptianHiero font, which displays the signs, and Djehuty, which types them.</p></div>
</div>

<h2 id="how">How it works</h2>
<div class="stepcards">
  <div class="stepcard">{icon("keyboard")}<h3>Type a code</h3><p>For example <code>kwi</code>. Each word in the dictionary has one or more transliteration codes.</p></div>
  <div class="stepcard">{icon("list")}<h3>Choose a word or string</h3><p>Press its number, or use the arrow keys and Return. The list learns: your usual choices rise to the top.</p></div>
  <div class="stepcard">{icon("layers")}<h3>The font does the layout</h3><p>Signs are grouped into quadrats automatically. There is no need for position markers or control characters.</p></div>
</div>

<div class="callout">
  {icon("layers")}
  <div>
    <h3>Ligatures</h3>
    <p>The font joins signs that belong together, so you never have to say how to stack or combine them. You only say where to keep them apart: type <code>0</code> and choose the first entry in the list, an invisible breaking character. It stops the font from joining the signs on either side.</p>
  </div>
</div>
<div class="figs">
  {fig("htp.jpg", "Typed in order: htp.", "The signs htp in sequence")}
  {fig("htp-qad.jpg", "Displayed as one quadrat.", "The signs htp set as a quadrat")}
</div>

<div class="callout">
  {icon("unlink")}
  <div>
    <h3>Breaking characters</h3>
    <p>Where two signs must stay apart, Djehuty inserts an invisible breaking character, the zero-width non-joiner (U+200C). It does not show in the text. <a href="quadrats.html">Quadrats and ligatures</a> and <a href="breaking.html">Breaking characters</a> explain both.</p>
  </div>
</div>
<div class="mini-figs">
  <figure><img src="{RAW}Without_Formatting_Marks.jpg" alt="Text without formatting marks"><figcaption>Without formatting marks.</figcaption></figure>
  <figure><img src="{RAW}With_Formatting_Marks.jpg" alt="Text with formatting marks"><figcaption>With formatting marks: the editor shows the character.</figcaption></figure>
</div>

<h2 id="install">How to get and install it</h2>
<div class="stepcards">
  <div class="stepcard">{icon("download")}<h3>Download</h3><p>Get <code>Djehuty.pkg</code> from the Releases page. macOS 12 or later, Intel and Apple silicon.</p></div>
  <div class="stepcard">{icon("check")}<h3>Install and log out</h3><p>Run the installer, which also installs the EgyptianHiero font. Then log out and back in.</p></div>
  <div class="stepcard">{icon("keyboard")}<h3>Add the input</h3><p>System Settings, Keyboard, Text Input, Edit. Add <em>Djehuty (Egyptian Hieroglyphs)</em>.</p></div>
  <div class="stepcard">{icon("gear")}<h3>Deploy</h3><p>Choose <em>Deploy</em> from the Djehuty menu bar icon. Repeat after each update.</p></div>
</div>
<div class="callout">
  {icon("info")}
  <div>
    <h3>If macOS blocks the installer</h3>
    <p>An unsigned installer may be reported as coming from an unidentified developer. Open System Settings, Privacy &amp; Security, and choose <em>Open Anyway</em>. The <a href="{BLOB}USER_GUIDE.md">user guide</a> has the full instructions.</p>
  </div>
</div>
""")

P["why-unicode.html"] = ("Why Unicode?", """
<p class="kicker">Background</p>
<h1>Why Unicode?</h1>
<p class="lede">Hieroglyphs as text, rather than as images.</p>
<p>Unicode hieroglyphs transcribe Egyptian signs as strings of text. Tools such as JSesh generate images, which can be accurate but cannot be searched, copied or stored as text. A Unicode hieroglyph can be inserted into any editor, manipulated like any other character, found with a search function, used in databases and tables, and kept searchable in a PDF.</p>
<h2>What they are for</h2>
<p>Unicode hieroglyphs are limited by the font that displays them, so they are not suited to palaeographically accurate copies of inscriptions. They are meant to transcribe texts in a uniform way: when a text is quoted and discussed for its literary or linguistic content, rather than for its appearance on the support.</p>
<p>The distinction is familiar from manuscript studies. A palaeographical copy reproduces each scribal peculiarity of form. A content-wise transcription, set in a standard typeface, serves the critical edition. Unicode hieroglyphs are meant for the Egyptological equivalent of the second.</p>
""")

P["typing.html"] = ("Typing reference", """
<p class="kicker">Using Djehuty</p>
<h1>Typing reference</h1>
<p class="lede">How codes, lists and paging work.</p>
<h2>Codes and the list</h2>
<p>Type a transliteration code. The matching words in hieroglyphs appear in a list. Press the number of your choice, or use the arrow keys and Return. Press <code>,</code> (comma) for the next page of the list; Page Up goes back.</p>
<p>The list learns: the signs you choose often for a code move up over time.</p>
<h2>Keys with alternatives</h2>
<p>Some keys offer a short list of conventional characters. The plain character comes first.</p>
<table>
  <thead><tr><th>Key</th><th>Choices</th></tr></thead>
  <tbody>
    <tr><td><code>[</code></td><td class="g">[ &nbsp; ⌜ &nbsp; ⌞</td></tr>
    <tr><td><code>]</code></td><td class="g">] &nbsp; ⌝ &nbsp; ⌟</td></tr>
    <tr><td><code>&lt;</code></td><td class="g">&lt; &nbsp; ⟨</td></tr>
    <tr><td><code>&gt;</code></td><td class="g">&gt; &nbsp; ⟩</td></tr>
    <tr><td><code>( ) { } |</code></td><td>the same character</td></tr>
    <tr><td><code>-</code></td><td>the same character</td></tr>
    <tr><td><code>=</code></td><td class="g">= &nbsp; ⸗</td></tr>
    <tr><td><code>.</code></td><td>the same character</td></tr>
    <tr><td><code>0</code>–<code>9</code></td><td>the digit, its superscript and its subscript, then the signs for that code</td></tr>
  </tbody>
</table>
<h2>Hyphens, question marks and case</h2>
<p>Some codes contain <code>-</code> or <code>?</code>, such as <code>pt-m-Aiw</code>. Type them exactly as they appear in the dictionary. Uppercase and lowercase codes are distinct: <code>kA</code> and <code>ka</code> may give different signs.</p>
""")

P["quadrats.html"] = ("Quadrats and ligatures", f"""
<p class="kicker">How the font works</p>
<h1>Quadrats and ligatures</h1>
<p class="lede">Why signs are typed in order and grouped by the font.</p>
<h2>The problem</h2>
<p>In actual texts, hieroglyphs are usually distributed into <em>quadrats</em>: virtual rectangles or squares that organise the signs in space. The sign group <em>htp</em> is commonly set as a single quadrat, not as a line.</p>
<div class="figs">
  {fig("htp.jpg", "The sequence, as encoded.", "The signs htp in sequence")}
  {fig("htp-qad.jpg", "The same sequence, set as a quadrat.", "The signs htp set as a quadrat")}
</div>
<h2>Ligatures</h2>
<p>The font does this through <em>ligatures</em>: substitutions stored in the font itself. Typography offers familiar examples. The English sequence <em>f</em> + <em>i</em> is set as a single ligature, and in Devanagari the sequence ह + म becomes one conjunct.</p>
<div class="figs">
  {fig("fi-fi.jpg", "The English sequence f + i.", "The letters f and i")}
  {fig("fi_lig.jpg", "Set as a ligature.", "The fi ligature")}
  {fig("ma-ha.jpg", "The Devanagari sequence ह + म.", "The Devanagari letters ha and ma")}
  {fig("ma-ha_lig.jpg", "Set as a conjunct.", "The ma-ha conjunct")}
</div>
<p>EgyptianHiero works the same way. When it meets a sequence of signs that matches one of its ligatures, it arranges them as the corresponding quadrat.</p>
<h2>What follows</h2>
<ul>
  <li><strong>No positional markers.</strong> Signs are typed one after the other. Unlike Manuel de Codage or JSesh, no characters such as <code>:</code>, <code>*</code> or <code>-</code> are needed.</li>
  <li><strong>Search still works.</strong> A quadrat still corresponds to its sequence, so search finds signs inside quadrats, and sequences that span several quadrats.</li>
  <li><strong>Only encoded quadrats.</strong> The font displays only the quadrats it encodes; custom quadrats cannot be built. Version 9.03 encodes about 10,600 ligatures, and new ones are added with each release. Requests for additional quadrats are welcome.</li>
</ul>
""")

P["breaking.html"] = ("Breaking characters", f"""
<p class="kicker">How the font works</p>
<h1>Breaking characters</h1>
<p class="lede">Keeping two signs apart when the font would join them.</p>
<h2>The problem</h2>
<p>The font applies ligatures in the direction of writing. If the pairs A–B and B–C both form ligatures, the sequence A–B–C always displays A–B, never B–C. Sometimes a ligature is also simply not wanted.</p>
<h2>The solution</h2>
<p>A <em>breaking ligature character</em> stops the font from joining two signs. It is invisible in the output. Djehuty uses the zero-width non-joiner (ZWNJ, U+200C), which is a joining control and does what is needed.</p>
<div class="note">Earlier versions of the project's text recommended the zero-width space (ZWSP, U+200B). That character marks where a line may break and is not a joining control, so Djehuty does not use it.</div>
<h2>Seeing the character</h2>
<p>Breaking characters are invisible, but many editors show them with the formatting marks option switched on.</p>
<div class="figs">
  {fig("Without_Formatting_Marks.jpg", "Without formatting marks.", "Text without formatting marks")}
  {fig("With_Formatting_Marks.jpg", "With formatting marks: the editor shows the character.", "Text with formatting marks")}
</div>
<h2>Where to use it</h2>
<ul>
  <li><strong>Only where needed.</strong> Use the character only to prevent specific wrong ligatures. This suits static texts such as articles and monographs.</li>
  <li><strong>Between every quadrat.</strong> Separate every pair of signs that should not join. This suits texts that will be edited or reused, such as corpora and databases, because the rendering then does not depend on which ligatures a later font version contains.</li>
</ul>
<p>Both examples below look the same on screen. Their underlying characters differ.</p>
<div class="figs">
  {fig("BLC-display.jpg", "How both sentences display.", "Two sentences as displayed")}
  {fig("BLC-hidden.jpg", "Their underlying characters.", "The underlying characters of the two sentences")}
</div>
<h2>Search</h2>
<p class="note">Search functions treat breaking characters differently. Some ignore them, and others do not. Test the program you use before relying on a search.</p>
""")

P["font.html"] = ("The font", """
<p class="kicker">Downloads</p>
<h1>The font</h1>
<p class="lede">EgyptianHiero, versions and credits.</p>
<p>EgyptianHiero is designed by Marwan Kilani (2017–2026). Its glyph outlines are based on Mark-Jan Nederhof's NewGardiner. The Djehuty installer provides version 9.03.</p>
<table>
  <thead><tr><th>File</th><th>Version</th><th>Notes</th></tr></thead>
  <tbody>
    <tr><td>EgyptianHiero (installer)</td><td>9.03</td><td>Installed by the Djehuty package; about 10,600 quadrat ligatures</td></tr>
    <tr><td>EgyptianHiero 4.03 (TTF)</td><td>4.03</td><td>Standalone download in the repository</td></tr>
    <tr><td>EgyptianHiero 3.03a (TTF, WOFF, WOFF2)</td><td>3.03a</td><td>Legacy; fewer ligatures, for basic tasks</td></tr>
  </tbody>
</table>
<p>All rights reserved by the designer. Redistribution requires the author's permission.</p>
""")

P["examples.html"] = ("Examples and citation", """
<p class="kicker">Reference</p>
<h1>Examples and citation</h1>
<p class="lede">Where the font is used, and how to cite it.</p>
<h2>In use</h2>
<p>Daniel A. Werning, <em>Digitale Einführung in die hieroglyphisch-ägyptische Schrift und Sprache</em>, Humboldt-Universität zu Berlin, 2018–. <a href="https://wikis.hu-berlin.de/ancientegyptian/Inhaltsverzeichnis">wikis.hu-berlin.de/ancientegyptian</a></p>
<p>If you have used the font or the input method in a publication, please write to the author so that this list can be updated.</p>
<h2>How to cite</h2>
<div class="cite">Kilani, Marwan. 2026. <em>Djehuty: Unicode font and input method for ancient Egyptian hieroglyphs</em>. Font version 9.03; input method version 0.1.29. <a href="https://github.com/MKilani/Djehuty">https://github.com/MKilani/Djehuty</a>.</div>
<p>Replace the version numbers with those of the release you used.</p>
""")

P["feedback.html"] = ("Feedback", """
<p class="kicker">Contact</p>
<h1>Feedback</h1>
<p class="lede">Questions, corrections and requests.</p>
<p>Please use the Issues tab of the repository for questions, corrections, and requests for quadrats or signs.</p>
<p>For a problem with the input method, include the log from the Djehuty menu in the menu bar, and say which version of macOS you use.</p>
<p>Comments on the choice of breaking character, and on the transliteration conventions in the dictionary, are particularly welcome.</p>
""")

FILES = {"index.html": "index.html"}
for name, (title, body) in P.items():
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        f.write(page(name, title, body))
print("built", len(P), "pages")
