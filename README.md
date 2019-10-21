# Djehuty

Djehuty is an ongoing project by Marwan Kilani (Freie Universität Berlin - Swiss National Science Foundation) aiming at the development of a Unicode font and Input Method for ancient Egyptian hieroglyphs.

A first working version of the font is already available and it is provided in the present repository.

A beta version of the Input Method will be published here soon.

## Font

   Font name: EgyptianHiero  
   Version: 4.02 - March 4 2019  
   Format: TrueType® Font

   Designed by Marwan Kilani, 2017-9.  
   Glyph outlines based on Mark-Jan Nederhof's font NewGardiner.  
   All Rights Reserved

### How to cite

Kilani Marwan, 2019, Djehuty - Font EgyptianHiero 4.02 (4.3.2019), https://github.com/MKilani/Djehuty

### How the font works, and how to use it correctly

#### The problem

In actual texts, hieroglpyhs are usually distributed into so-called "quadrats", namely virtual rectangles or squares that provide a conceptual frame to organize the signs into space. For instance, the signs 

![Alt text](imagesReadme/htp1.pdf)

xxxHtp, are usually not written in a linear sequence, one after the other, but they are rather reorganized within a single quadrat, in the form xxx.

In contrast with other fonts, which display hieroglpyhs only in linear sequences, EgyptianHiero reorganize the signs into quadrats.

#### Ligatures for quadrats

In order to organize and display the hieroglyphs into quadrats, the EgyptianHiero font uses a series of *ligatures* pre-encoded in the font itself.

In order to understand what this means, take the example of the English ligature f+f+l > ﬄ or the Hindi ligature ह + म > ह्म . In these cases, fonts that support ligatures will automatically turn any sequence f+f+l or  ह + म into their corresponding ligatures, thus displaying them as ﬄ or ह्म respectively.

EgyptianHiero uses the same mechanism to organize signs into quadrats: every time the font encounter a sequence of signs corresponding to one of its pre-encoded ligatures, it will reorganize the signs into quadrats accordingly.

Therefore, every time the font will encounter a sequence htpxxx, it will display it as a ligature xxx.

This approach has a series of implications that need to be considered:

1. Since ligatures are embedded in the font and automatically rendered, there is no need to use any special character to indicate the relative position of the signs. Just input the hieroglyphs one after the other, the font will take care of grouping them into quadrats.

2. Since no special character is used, a quadrat xxx will still correspond to an underlying sequence xxx. This means that in general search functions (e.g. in online search engines or text files and text editors) can find signs within quadrats, and can even find sequences of signes spreads among different quadrats.

3. Only ligatures, i.e. only quadrats that are pre-encoded in the font can be displayed by the font. This is an important point: one cannot display custom quadrats using EgyptianHiero -- only the quadrats that are already encoded in the font can be displayed. 

Moreover, the font already contain over 3000 ligatures/quadrats, and new are added with any new release. Right now, most quadrats attested in the TLA are encoded, as well as many other extracted from various Late Egyptian texts. Most texts can thus be transcribed without relevant issues. However, I am still adding ligatures, as I encounter new quadrats in the texts I am working on - obviously the more texts one is transcribing, the more quadrats are encountered.

In this respect, Users are encouraged to send me any additional quadrat they would like to have in the font and I will gladely add them in the next release.

#### Breaking ligatures

As said, EgyptianHiero does not use any special character to create quadrats -- quadrats are created automatically every time the font encounter a relevant sequence of characters. There are cases, however, in which one may NOT want two signs to be combined into a ligature. In other cases, there could be conflicts between ligatures, as the font process ligatures according the direction of writing. This means that if e.g. both the signs A-B and the signs B-C form a ligature, in the case of a sequence A-B-C, the font will always display the ligature A-B (which comes first) and never the ligature B-C (which follows).

##### Breaking Ligature Character

This issue can be easily solved by using a Breaking Ligature Character (BLC), namely a special character than is invisible and prevent the font to join two signs into a quadrat. The best sign to use for this purpose is the special character Zero-width space (ZWSP -- unicode U+200B -- see xxx https://en.wikipedia.org/wiki/Zero-width_space ).

An alternative sign that could be used is the Zero-width non-joiner (ZWNJ -- uncode U+200C -- see xxx https://en.wikipedia.org/wiki/Zero-width_non-joiner ).

For now, I prefer the first as it is easier to manipulate in text editors like LibreOffice, but any consideration, comment or suggestion on this point is welcome.


##### Search with Breaking Ligature Character

ZWSP are currently used in various major scripts, such as Japanese. Therefore, search engines, browsers and text editors are already aware of them.

Browsers and online search engines deal with the ZWSP in different ways. Some just ignore it, which means that sequences of hieroglyphs can be found even though they are distributed over different quadrats separated by ZWSP.

As for text editors, they often have search functions that ignore white spaces. These functions can be used to ignore ZWSP.

These features, however, tend to change from one version to the other, and more testing to define the specific behavior of every software and version is needed. Here as well, any consideration, comment or suggestion is welcome.

##### Visualizing the Breaking Ligature Character

The ZWSP is invisible in the final output, but various text editors allow displaying it together with other Formatting Marks when the Formatting Marks option is activated. 
Therefore, for instance


##### When to use the Breaking Ligature Character -- suggest best practice

Breaking Ligature Characters can be used in two ways.

The first option is to use them only to prevent the display of specific wrong ligatures.

The second option is to use them between every quadrat and in general to separate every sign that is not supposed to form a ligature.

Take the following two examples: the two sentences in the image are displyed exactly in the same way:

xxx

Their underlying structure, however, is different, one reflectign the first approach, the other reflectign the second.

xxx

Both approaches are valid, depending on the context and use of the text.

In case of texts that are expected to be used and edited in the future, I suggest to use the second approach, as it ensure compatibility with future versions of the font -- by separating ever sign that should NOT be joined by a ligature, one is sure that the rendition of the text will not be affected by the addition of new ligatures in future versions of the font.






### Examples

The font EgyptianHiero has being used in the following projects and publications:

* **Digitale Einführung in die hieroglyphisch-ägyptische Schrift und Sprache**  
   Daniel A. Werning  
   Humboldt-Universität zu Berlin: Berlin 2018–...  
   https://wikis.hu-berlin.de/ancientegyptian/Inhaltsverzeichnis

## Input Method

Coming soon.

---

Last Update: 15.8.2019
