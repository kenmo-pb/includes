; +---------+
; | Podcast |
; +---------+
; | 2017-08-17 . Creation
; | 2017-09-26 . Items are now populated
; | 2017-10-13 . Real buildDate/pubDate attributes
; | 2018-01-07 . Fixed last of escaping in 'itunes:subtitle', 255 char limit
; | 2018-04-30 . Added per-episode 'itunes:image' attribute
; | 2018-06-15 . Added Reverse episode order option
; | 2018-06-25 . Added per-episode 'Link' attribute
; | 2018-07-14 . Cleaned up demo

; TODO
; add more possible "item" attributes

CompilerIf (Not Defined(__Podcast_Included, #PB_Constant))
#__Podcast_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf



;-
;- Structures

Structure PODCASTITEM
  GUID.s
  Link.s
  Title.s
  UTCDate.i
  Desc.s
  Seconds.i
  Image.s
EndStructure

Structure PODCAST
  Title.s
  Description.s
  Website.s
  Copyright.s
  FeedURL.s
  Email.s
  Author.s
  Image.s
  List Item.PODCASTITEM()
  Reverse.i
EndStructure

;-
;- Imports

CompilerIf (Not Defined(time, #PB_Procedure))
  ImportC ""
    time(*seconds.Integer = #Null)
  EndImport
CompilerEndIf

;-
;- Procedures

Procedure.s PodcastDateString(UTCDate.i)
  Protected Result.s
  Result = Mid("SunMonTueWedThuFriSat", 1 + DayOfWeek(UTCDate)*3, 3) + ", "
  Result + RSet(Str(Day(UTCDate)), 2, "0") + " "
  Result + Mid("JanFebMarAprMayJunJulAugSepOctNovDec", 1 + (Month(UTCDate)-1)*3, 3) + " "
  Result + RSet(Str(Year(UTCDate)), 4, "0") + " "
  Result + RSet(Str(Hour(UTCDate)), 2, "0") + ":"
  Result + RSet(Str(Minute(UTCDate)), 2, "0") + ":"
  Result + RSet(Str(Second(UTCDate)), 2, "0") + " "
  Result + "+0000"
  ProcedureReturn (Result)
EndProcedure

Procedure.s PodcastEscape(Text.s)
  Text = ReplaceString(Text, "&", "&amp;")
  Text = ReplaceString(Text, "<", "&lt;")
  Text = ReplaceString(Text, ">", "&gt;")
  ProcedureReturn (Text)
EndProcedure

Procedure.s ComposePodcast(*Pod.PODCAST)
  Protected Result.s
  Protected Indent.i = 2
  Protected DefDate.i = time()
  Protected BuildDateString.s = PodcastDateString(DefDate)
  If (*Pod)
    Result + Space(0 * Indent) + "<?xml version='1.0' encoding='UTF-8' ?>" + #LF$
    Result + Space(0 * Indent) + "<rss xmlns:itunes='http://www.itunes.com/dtds/podcast-1.0.dtd' version='2.0' xmlns:atom='http://www.w3.org/2005/Atom'>" + #LF$
    Result + Space(1 * Indent) + "<channel>" + #LF$
    Result + Space(2 * Indent) + "" + #LF$
    Result + Space(2 * Indent) + "<title>" + PodcastEscape(*Pod\Title) + "</title>" + #LF$
    Result + Space(2 * Indent) + "<description>" + PodcastEscape(*Pod\Description) + "</description>" + #LF$
    Result + Space(2 * Indent) + "<link>" + PodcastEscape(*Pod\Website) + "</link>" + #LF$
    Result + Space(2 * Indent) + "<language>en-us</language>" + #LF$
    If (*Pod\Copyright)
      Result + Space(2 * Indent) + "<copyright>" + PodcastEscape(*Pod\Copyright) + "</copyright>" + #LF$
    Else
      Result + Space(2 * Indent) + "<copyright>Copyright " + Str(Year(Date())) + "</copyright>" + #LF$
    EndIf
    Result + Space(2 * Indent) + ReplaceString("<lastBuildDate>$1</lastBuildDate>", "$1", BuildDateString) + #LF$
    Result + Space(2 * Indent) + ReplaceString("<pubDate>$1</pubDate>", "$1", BuildDateString) + #LF$
    Result + Space(2 * Indent) + "<docs>http://blogs.law.harvard.edu/tech/rss</docs>" + #LF$
    If (*Pod\Author)
      Result + Space(2 * Indent) + "<webMaster>" + *Pod\Email + " (" + *Pod\Author + ")</webMaster>" + #LF$
    Else
      Result + Space(2 * Indent) + "<webMaster>" + *Pod\Email + "</webMaster>" + #LF$
    EndIf
    Result + Space(2 * Indent) + "<atom:link href='" + *Pod\FeedURL + "' rel='self' type='application/rss+xml' />" + #LF$
    Result + Space(2 * Indent) + "" + #LF$
    Result + Space(2 * Indent) + "<itunes:author>" + PodcastEscape(*Pod\Author) + "</itunes:author>" + #LF$
    Result + Space(2 * Indent) + ReplaceString("<itunes:subtitle>$1</itunes:subtitle>", "$1", PodcastEscape(Left(*Pod\Description, 255))) + #LF$
    Result + Space(2 * Indent) + ReplaceString("<itunes:summary>$1</itunes:summary>", "$1", PodcastEscape(*Pod\Description)) + #LF$
    Result + Space(2 * Indent) + "<itunes:owner>" + #LF$
    Result + Space(3 * Indent) + "<itunes:name>" + PodcastEscape(*Pod\Author) + "</itunes:name>" + #LF$
    Result + Space(3 * Indent) + "<itunes:email>" + PodcastEscape(*Pod\Email) + "</itunes:email>" + #LF$
    Result + Space(2 * Indent) + "</itunes:owner>" + #LF$
    Result + Space(2 * Indent) + "<itunes:explicit>No</itunes:explicit>" + #LF$
    Result + Space(2 * Indent) + ReplaceString("<itunes:image href='$1' />", "$1", PodcastEscape(*Pod\Image)) + #LF$
    Result + Space(2 * Indent) + "<itunes:category text='Music' />" + #LF$
    Result + Space(2 * Indent) + "" + #LF$
    
    Protected Valid.i
    If (*Pod\Reverse)
      Valid = LastElement(*Pod\Item())
    Else
      Valid = FirstElement(*Pod\Item())
    EndIf
    While (Valid)
      Result + Space(2 * Indent) + "<item>" + #LF$
      Result + Space(3 * Indent) + ReplaceString("<title>$1</title>", "$1", PodcastEscape(*Pod\Item()\Title)) + #LF$
      If (*Pod\Item()\Link)
        Result + Space(3 * Indent) + ReplaceString("<link>$1</link>", "$1", PodcastEscape(*Pod\Item()\Link)) + #LF$
      Else
        Result + Space(3 * Indent) + ReplaceString("<link>$1</link>", "$1", PodcastEscape(*Pod\Website)) + #LF$
      EndIf
      Result + Space(3 * Indent) + ReplaceString("<guid>$1</guid>", "$1", PodcastEscape(*Pod\Item()\GUID)) + #LF$
      Result + Space(3 * Indent) + ReplaceString("<description>$1</description>", "$1", PodcastEscape(*Pod\Item()\Desc)) + #LF$
      Result + Space(3 * Indent) + ReplaceString(ReplaceString("<enclosure url='$1' length='$2' type='audio/mpeg' />", "$1", PodcastEscape(*Pod\Item()\GUID)), "$2", Str(1024*1024*50)) + #LF$
      Result + Space(3 * Indent) + "<category>Music</category>" + #LF$
      If (*Pod\Item()\UTCDate)
        Result + Space(3 * Indent) + ReplaceString("<pubDate>$1</pubDate>", "$1", PodcastDateString(*Pod\Item()\UTCDate)) + #LF$
      Else
        Result + Space(3 * Indent) + ReplaceString("<pubDate>$1</pubDate>", "$1", PodcastDateString(DefDate)) + #LF$
        DefDate + 60
      EndIf
      Result + Space(3 * Indent) + ReplaceString("<itunes:author>$1</itunes:author>", "$1", PodcastEscape(*Pod\Author)) + #LF$
      Result + Space(3 * Indent) + "<itunes:explicit>No</itunes:explicit>" + #LF$
      Result + Space(3 * Indent) + ReplaceString("<itunes:subtitle>$1</itunes:subtitle>", "$1", PodcastEscape(Left(*Pod\Item()\Desc, 255))) + #LF$
      If (*Pod\Item()\Image)
        Result + Space(3 * Indent) + ReplaceString("<itunes:image href='$1'/>", "$1", PodcastEscape(*Pod\Item()\Image)) + #LF$
      EndIf
      If (*Pod\Item()\Seconds > 0)
        Result + Space(3 * Indent) + ReplaceString("<itunes:duration>$1</itunes:duration>", "$1", FormatDate("%hh:%ii:%ss", *Pod\Item()\Seconds)) + #LF$
      Else
        Result + Space(3 * Indent) + "<itunes:duration>1:00:00</itunes:duration>" + #LF$
      EndIf
      Result + Space(2 * Indent) + "</item>" + #LF$
      If (*Pod\Reverse)
        Valid = PreviousElement(*Pod\Item())
      Else
        Valid = NextElement(*Pod\Item())
      EndIf
    Wend
    
    Result + Space(2 * Indent) + "" + #LF$
    Result + Space(1 * Indent) + "</channel>" + #LF$
    Result + Space(0 * Indent) + "</rss>" + #LF$
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i SavePodcast(*Pod.PODCAST, File.s)
  Protected Result.i = #False
  If (*Pod)
    Protected FN.i = CreateFile(#PB_Any, File)
    If (FN)
      WriteString(FN, ComposePodcast(*Pod))
      CloseFile(FN)
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i CreatePodcast(Title.s)
  Protected *Pod.PODCAST = AllocateStructure(PODCAST)
  If (*Pod)
    *Pod\Title = Title
  EndIf
  ProcedureReturn (*Pod)
EndProcedure

Procedure.i FreePodcast(*Pod.PODCAST)
  If (*Pod)
    FreeStructure(*Pod)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure SetPodcastDescription(*Pod.PODCAST, Text.s)
  If (*Pod)
    *Pod\Description = Text
  EndIf
EndProcedure

Procedure SetPodcastWebsite(*Pod.PODCAST, URL.s)
  If (*Pod)
    If (URL And (Not FindString(URL, "://")))
      URL = "http://" + URL
    EndIf
    *Pod\Website = URL
  EndIf
EndProcedure

Procedure SetPodcastCopyright(*Pod.PODCAST, Text.s)
  If (*Pod)
    *Pod\Copyright = Text
  EndIf
EndProcedure

Procedure SetPodcastEmail(*Pod.PODCAST, Email.s)
  If (*Pod)
    *Pod\Email = Email
  EndIf
EndProcedure

Procedure SetPodcastFeedURL(*Pod.PODCAST, URL.s)
  If (*Pod)
    If (URL And (Not FindString(URL, "://")))
      URL = "http://" + URL
    EndIf
    *Pod\FeedURL = URL
  EndIf
EndProcedure

Procedure SetPodcastAuthor(*Pod.PODCAST, Author.s)
  If (*Pod)
    *Pod\Author = Author
  EndIf
EndProcedure

Procedure SetPodcastImage(*Pod.PODCAST, Image.s)
  If (*Pod)
    *Pod\Image = Image
  EndIf
EndProcedure

Procedure AddPodcastItem(*Pod.PODCAST, GUID.s, Title.s = "", UTCDate.i = 0, Desc.s = "", Seconds.i = 0, Image.s = "", Link.s = "")
  If (*Pod)
    AddElement(*Pod\Item())
    *Pod\Item()\GUID = GUID
    *Pod\Item()\Title = Title
    *Pod\Item()\UTCDate = UTCDate
    *Pod\Item()\Desc = Desc
    *Pod\Item()\Seconds = Seconds
    *Pod\Item()\Image = Image
    *Pod\Item()\Link = Link
  EndIf
EndProcedure

Procedure ReversePodcastOrder(*Pod.PODCAST, Reverse.i = #True)
  If (*Pod)
    *Pod\Reverse = Bool(Reverse)
  EndIf
EndProcedure



;-
;- Demo Program
CompilerIf (#PB_Compiler_IsMainFile)
DisableExplicit

*Pod = CreatePodcast("Purecast")
If (*Pod)
  SetPodcastDescription(*Pod, "Create podcast feeds in PureBasic")
  SetPodcastWebsite(*Pod, "http://www.purebasic.com")
  SetPodcastCopyright(*Pod, "Copyright " + Str(Year(Date())))
  SetPodcastEmail(*Pod, "feed@purebasic.com")
  SetPodcastFeedURL(*Pod, "http://purebasic.com/feed.xml")
  SetPodcastAuthor(*Pod, "PB Author")
  SetPodcastImage(*Pod, "http://purebasic.com/images/logopb.gif")
  
  AddPodcastItem(*Pod, "http://purebasic.com/ep01.mp3", "My MP3")
  
  Debug ComposePodcast(*Pod)
  
  FreePodcast(*Pod)
EndIf

CompilerEndIf
CompilerEndIf
;-