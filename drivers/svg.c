/* November 8, 2006

	PLplot driver for SVG 1.1 (http://www.w3.org/Graphics/SVG/)

	Copyright (C) 2006 Hazen Babcock

	This file is part of PLplot.

	PLplot is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Library Public License as published
	by the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	PLplot is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Library General Public License for more details.

	You should have received a copy of the GNU Library General Public License
	along with PLplot; if not, write to the Free Software
	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
   	
*/

/*---------------------------------------------
  Header files, defines and local variables
  ---------------------------------------------*/

#include <stdarg.h>
#include <math.h>

/* PLplot header files */

#include "plplotP.h"
#include "drivers.h"

/* constants */

#define SVG_Default_X	720
#define SVG_Default_Y	540

/* This is a bit arbitrary. I adjusted it to get the graphs to be about
   the same size as the graphs generated by some of the other devices. */

#define DPI             90  

#define MAX_STRING_LEN	1000

/* local variables */

PLDLLEXPORT const char* plD_DEVICE_INFO_svg = "svg:Scalable Vector Graphics (SVG 1.1):1:svg:57:svg";

static int canvasXSize = 0;
static int canvasYSize = 0;

static int svgIndent = 0;
static FILE *svgFile;

static char curColor[7];

/* font stuff */

/* Debugging extras */

/*-----------------------------------------------
  function declarations
  -----------------------------------------------*/

/* Functions for writing XML SVG tags to a file */

static void svg_open(char *);
static void svg_open_end(void);
static void svg_attr_value(char *, char *);
static void svg_attr_values(char *, char *, ...);
static void svg_close(char *);
static void svg_general(char *);
static void svg_indent(void);
static void svg_stroke_width(PLStream *);
static void svg_stroke_color(PLStream *);
static void svg_fill_color(PLStream *);
static void svg_fill_background_color(PLStream *);

/* General */

static void poly_line(PLStream *, short *, short *, PLINT, short);
static void write_hex(unsigned char);
static void write_unicode(PLUNICODE);
static short desired_offset(short, double);
static void specify_font(PLUNICODE);

/* String processing */

static void proc_str(PLStream *, EscText *);

/* PLplot interface functions */

PLDLLEXPORT void plD_dispatch_init_svg      (PLDispatchTable *pdt);
void plD_init_svg               (PLStream *);
void plD_line_svg               (PLStream *, short, short, short, short);
void plD_polyline_svg   		(PLStream *, short *, short *, PLINT);
void plD_eop_svg                (PLStream *);
void plD_bop_svg                (PLStream *);
void plD_tidy_svg               (PLStream *);
void plD_state_svg              (PLStream *, PLINT);
void plD_esc_svg                (PLStream *, PLINT, void *);

/*---------------------------------------------------------------------
  dispatch_init_init()
  
  Initialize device dispatch table
  ---------------------------------------------------------------------*/

void plD_dispatch_init_svg(PLDispatchTable *pdt)
{
#ifndef ENABLE_DYNDRIVERS
   pdt->pl_MenuStr  = "Scalable Vector Graphics (SVG 1.1)";
   pdt->pl_DevName  = "svg";
#endif
   pdt->pl_type     = plDevType_FileOriented;
   pdt->pl_seq      = 57;
   pdt->pl_init     = (plD_init_fp)     plD_init_svg;
   pdt->pl_line     = (plD_line_fp)     plD_line_svg;
   pdt->pl_polyline = (plD_polyline_fp) plD_polyline_svg;
   pdt->pl_eop      = (plD_eop_fp)      plD_eop_svg;
   pdt->pl_bop      = (plD_bop_fp)      plD_bop_svg;
   pdt->pl_tidy     = (plD_tidy_fp)     plD_tidy_svg;
   pdt->pl_state    = (plD_state_fp)    plD_state_svg;
   pdt->pl_esc      = (plD_esc_fp)      plD_esc_svg;
}

/*---------------------------------------------------------------------
  svg_init()
  
  Initialize device
  ---------------------------------------------------------------------*/

void plD_init_svg(PLStream *pls)
{

   pls->termin = 0;			/* not an interactive device */
   pls->color = 1;			/* supports color */
   pls->width = 1;
   pls->verbose = 1;
   pls->bytecnt = 0;
   /*pls->debug = 1;*/
   pls->dev_text = 1;		/* handles text */
   pls->dev_unicode = 1; 	/* wants text as unicode */
   pls->page = 0;
   pls->dev_fill0 = 1;		/* supports hardware solid fills */
   pls->dev_fill1 = 1;

   pls->graphx = GRAPHICS_MODE;

   if (!pls->colorset)
      pls->color = 1; 

   /* Set up device parameters */
   
   plP_setpxl(DPI/25.4, DPI/25.4);           /* Pixels/mm. */

   /* Set the bounds for plotting.  default is SVG_Default_X x SVG_Default_Y unless otherwise specified. */
   
   if (pls->xlength <= 0 || pls->ylength <= 0){
      canvasXSize = SVG_Default_X;
      canvasYSize = SVG_Default_Y;
      plP_setphy((PLINT) 0, (PLINT) SVG_Default_X, (PLINT) 0, (PLINT) SVG_Default_Y);
   } else {
      canvasXSize = pls->xlength;
      canvasYSize = pls->ylength;
      plP_setphy((PLINT) 0, (PLINT) pls->xlength, (PLINT) 0, (PLINT) pls->ylength);
   }   

   /* Prompt for a file name if not already set */
    
   plOpenFile(pls);
   svgFile = pls->OutFile;

   svgIndent = 0;
   svg_open("?xml version=\"1.0\" encoding=\"UTF-8\"?>");
}

/*----------------------------------------------------------------------
  svg_bop()
  
  Set up for the next page.
  ----------------------------------------------------------------------*/

void plD_bop_svg(PLStream *pls)
{
   pls->page++;
   
   /* write opening svg tag for the new page */
      
   svg_open("svg");
   svg_attr_value("xmlns", "http://www.w3.org/2000/svg");
   svg_attr_value("xmlns:xlink", "http://www.w3.org/1999/xlink");
   svg_attr_value("version", "1.1");   
   /* svg_attr_values("width", "%dcm", (int)((double)canvasXSize/DPI * 2.54)); */
   /* svg_attr_values("height", "%dcm", (int)((double)canvasYSize/DPI * 2.54)); */
   svg_attr_values("width", "%dpt", canvasXSize);
   svg_attr_values("height", "%dpt", canvasYSize);
   svg_attr_values("viewBox", "%d %d %d %d", 0, 0, canvasXSize, canvasYSize);
   svg_general(">\n");

   /* set the background by drawing a rectangle that is the size of
      of the canvas and filling it with the background color. */
   
   svg_open("rect");
   svg_attr_values("x", "%d", 0);
   svg_attr_values("y", "%d", 0);
   svg_attr_values("width", "%d", canvasXSize);
   svg_attr_values("height", "%d", canvasYSize);
   svg_attr_value("stroke", "none");
   svg_fill_background_color(pls);
   svg_open_end();
   
   /* invert the coordinate system so that PLplot graphs appear right side up */
   
   svg_open("g");
   svg_attr_values("transform", "matrix(1 0 0 -1 0 %d)", canvasYSize);
   svg_general(">\n");
}

/*---------------------------------------------------------------------
  svg_line()
  
  Draw a line in the current color from (x1,y1) to (x2,y2).
  ---------------------------------------------------------------------*/

void plD_line_svg(PLStream *pls, short x1a, short y1a, short x2a, short y2a)
{
   svg_open("polyline");
   svg_stroke_width(pls);
   svg_stroke_color(pls);
   svg_attr_value("fill", "none");
   /*   svg_attr_value("shape-rendering", "crisp-edges"); */
   svg_attr_values("points", "%d,%d %d,%d", x1a, y1a, x2a, y2a);
   svg_open_end();
}

/*---------------------------------------------------------------------
  svg_polyline()
  
  Draw a polyline in the current color.
  ---------------------------------------------------------------------*/

void plD_polyline_svg(PLStream *pls, short *xa, short *ya, PLINT npts)
{
   poly_line(pls, xa, ya, npts, 0);
}

/*---------------------------------------------------------------------
  svg_eop()
  
  End of page
  ---------------------------------------------------------------------*/

void plD_eop_svg(PLStream *pls)
{
  /* write the closing svg tag */

   svg_close("g");
   svg_close("svg");
}

/*---------------------------------------------------------------------
  svg_tidy()
  
  Close graphics file or otherwise clean up.
  ---------------------------------------------------------------------*/

void plD_tidy_svg(PLStream *pls)
{
   fclose(svgFile);
}

/*---------------------------------------------------------------------
  plD_state_svg()
  
  Handle change in PLStream state (color, pen width, fill attribute, etc).
  
  Nothing is done here because these attributes are aquired from 
  PLStream for each element that is drawn.
  ---------------------------------------------------------------------*/

void plD_state_svg(PLStream *pls, PLINT op)
{
}

/*---------------------------------------------------------------------
  svg_esc()
  
  Escape function.
  ---------------------------------------------------------------------*/

void plD_esc_svg(PLStream *pls, PLINT op, void *ptr)
{
  int     i;
  switch (op)
    {
    case PLESC_FILL:      /* fill polygon */
      poly_line(pls, pls->dev_x, pls->dev_y, pls->dev_npts, 1);
      break;
    case PLESC_HAS_TEXT:  /* render text */
      proc_str(pls, (EscText *)ptr);
      break;
    }
}

/*---------------------------------------------------------------------
  poly_line()
  
  Handles drawing filled and unfilled polygons
  ---------------------------------------------------------------------*/

void poly_line(PLStream *pls, short *xa, short *ya, PLINT npts, short fill)
{
   int i;

   svg_open("polyline");
   svg_stroke_width(pls);
   svg_stroke_color(pls);
   if(fill){
      svg_fill_color(pls);
   } else {
      svg_attr_value("fill", "none");
   }
   /*   svg_attr_value("shape-rendering", "crisp-edges"); */
   svg_indent();
   fprintf(svgFile, "points=\"");
   for (i = 0; i < npts; i++){
      fprintf(svgFile, "%d,%d ", xa[i], ya[i]);
      if(((i+1)%10) == 0){
         fprintf(svgFile,"\n");
         svg_indent();
      }
   }
   fprintf(svgFile, "\"/>\n");
   svgIndent -= 2;
}

/*---------------------------------------------------------------------
  proc_str()
  
  Processes strings for display.
  
  NOTE:
  
  (1) This was tested on Firefox and Camino where it seemed to display
  text properly. However, it isn't obvious to me that these browsers
  conform to the specification. Basically the issue is that some of 
  the text properties (i.e. dy) that you specify inside a tspan element 
  remain in force until the end of the text element. It would seem to 
  me that they should only apply inside the tspan tag. To get around
  this, and because it was easier anyway, I used what is essentially
  a list of tspan tags rather than a tree of tspan tags. Perhaps
  better described as a tree with one branch?
  
  (2) To deal with the some whitespace annoyances, the entire text
  element must be written on a single line. If there are lots of
  format characters then this line might end up being too long
  for some SVG implementations.
  
  (3) Text placement is not ideal. Vertical offset seems to be
  particularly troublesome.
  
  (4) See additional notes in specify_font re. to sans / serif
  
  ---------------------------------------------------------------------*/

void proc_str (PLStream *pls, EscText *args)
{
   char plplot_esc;
   short i;
   short upDown = 0;
   short totalTags = 1;
   short ucs4Len = args->unicode_array_len;
   short lastOffset = 0;
   double ftHt;
   PLUNICODE fci;
   PLFLT rotation, shear, stride, cos_rot, sin_rot, sin_shear, cos_shear;
   PLFLT t[4];
   /*   PLFLT *t = args->xform; */
   PLUNICODE *ucs4 = args->unicode_array;

   /* check that we got unicode */
   if(ucs4Len == 0){
      printf("Non unicode string passed to SVG driver, ignoring\n");
      return;
   }

   /* get plplot escape character and the current font */
   plgesc(&plplot_esc);
   plgfci(&fci);

   /* determine the font height */
   ftHt = 1.5 * pls->chrht * DPI/25.4;

   /* Calculate the tranformation matrix for SVG based on the
      transformation matrix provived by PLplot. */
   plRotationShear(args->xform, &rotation, &shear, &stride);
   /* N.B. Experimentally, I (AWI) have found the svg rotation angle is
      the negative of the libcairo rotation angle, and the svg shear angle
      is pi minus the libcairo shear angle. */
   cos_rot = cos(rotation);
   sin_rot = -sin(rotation);
   sin_shear = sin(shear);
   cos_shear = -cos(shear);
   t[0] = cos_rot;
   t[1] = -sin_rot;
   t[2] = cos_rot * sin_shear + sin_rot * cos_shear;
   t[3] = -sin_rot * sin_shear + cos_rot * cos_shear;

   /* Apply coordinate transform for text display.
      The transformation also defines the location of the text in x and y. */
   svg_open("g");
   svg_attr_values("transform", "matrix(%f %f %f %f %d %d)", t[0], t[1], t[2], t[3], args->x, (int)(args->y - 0.3*ftHt + 0.5));
   svg_general(">\n");

   /*--------------
     open text tag
     --------------*/

   svg_open("text");
   
   /* I believe this property to be important, but I'm not sure what the right value is.
      In example 2 the numbers are all over the place vertically. Perhaps that could
      be controlled in some way with this parameter? */
   svg_attr_value("dominant-baseline","no-change"); 
   
   /* The text goes at zero in x since the coordinate transform also defined the location of the text */
   svg_attr_value("x", "0");
   svg_attr_value("y", "0");

/* Tentavively removed. The examples, or at least Example 1, seem to expect
   the driver to ignore the text baseline, so the baseline adjustment is
   now done the text transform is applied above.

   /* Set the baseline of the string by adjusting the y offset
   Values were arrived at by trial and error. Unfortunately they don't seem to
   right in all cases, presumably due to adjustments being performed by
   my svg renderer. 

   if (args->base == 2){
     /* Align to the top of the text, and probably wrong. 
      svg_attr_values("y", "%d", (int)(0.7*ftHt + 0.5));
   }
   else if (args->base == 1){
     /* Align to the bottom of the text.
	
     This was adjusted based on example1 so that the symbols would be centered
     on the line. It is strange that it should have the same value as align
     to the middle of the text.
     
      svg_attr_values("y", "%d", (int)(0.3*ftHt + 0.5));  
   }
   else{
     /* Align to the middle of the text
	
     This was adjusted based on example1 so that the axis label text would be centered
     on the appropriate tick mark. Strangely, some seem to end up on the high side
     and others on the low side. Perhaps this is due rounding to the nearest pixel?
     
      svg_attr_values("y", "%d", (int)(0.3*ftHt + 0.5));
   }
*/
   
   /* set font color */
   svg_fill_color(pls);
   
   /* white space preserving mode */
   svg_attr_value("xml:space","preserve"); 
   
   /* set the font size */
   svg_attr_values("font-size","%d", (int)ftHt);
   
   /* set the justification, svg only supports 3 options so we round appropriately */
   
   if (args->just < 0.33)
     svg_attr_value("text-anchor", "start");   /* left justification */
   else if (args->just > 0.66)
     svg_attr_value("text-anchor", "end");     /* right justification */
   else
     svg_attr_value("text-anchor", "middle");  /* center */
            
   fprintf(svgFile,">");

   /* specify the initial font */
   specify_font(fci);

   /*----------------------------------------------------------
     Write the text with formatting
     We just keep stacking up tspan tags, then close them all
     after we have written out all of the text.
     ----------------------------------------------------------*/

   i = 0;
   while (i < ucs4Len){
     if (ucs4[i] < PL_FCI_MARK){	/* not a font change */
       if (ucs4[i] != (PLUNICODE)plplot_esc) {  /* a character to display */
	 write_unicode(ucs4[i]);
	 i++;
	 continue;
       }
       i++;
       if (ucs4[i] == (PLUNICODE)plplot_esc){   /* a escape character to display */
	 write_unicode(ucs4[i]);
	 i++;
	 continue;
       }
       else {
	 if(ucs4[i] == (PLUNICODE)'u'){	/* Superscript */
	   totalTags++;
	   upDown++;
	   fprintf(svgFile,"<tspan dy=\"%d\" font-size=\"%d\">", desired_offset(upDown, ftHt) - lastOffset, (int)(ftHt * pow(0.8, abs(upDown))));
	   lastOffset = desired_offset(upDown, ftHt);
	 }
	 if(ucs4[i] == (PLUNICODE)'d'){	/* Subscript */
	   totalTags++;
	   upDown--;
	   fprintf(svgFile,"<tspan dy=\"%d\" font-size=\"%d\">", desired_offset(upDown, ftHt) - lastOffset, (int)(ftHt * pow(0.8, abs(upDown))));
	   lastOffset = desired_offset(upDown, ftHt);
	 }
	 i++;
       }
     }
     else { /* a font change */
       specify_font(ucs4[i]);         
       totalTags++;
       i++;
     }
   }

   /*----------------------------------------------
     close out all the tspan tags and the text tag
     ----------------------------------------------*/
   
   for(i=0;i<totalTags;i++){
      fprintf(svgFile,"</tspan>");
   }
   fprintf(svgFile,"\n");
   
   svg_close("text");
   svg_close("g");
}

/*---------------------------------------------------------------------
  svg_open ()
  
  Used to open a new XML expression, sets the indent level appropriately
  ---------------------------------------------------------------------*/

void svg_open (char *tag)
{
   svg_indent();
   fprintf(svgFile, "<%s\n", tag);
   svgIndent += 2;
}

/*---------------------------------------------------------------------
  svg_open_end ()
  
  Used to end the opening of a new XML expression i.e. add 
  the final ">".
  ---------------------------------------------------------------------*/

void svg_open_end (void)
{
   svg_indent();
   fprintf(svgFile, "/>\n");
   svgIndent -= 2;
}

/*---------------------------------------------------------------------
  svg_attr_value ()
  
  Prints two strings to svgFile as a XML attribute value pair
  i.e. foo="bar"
  ---------------------------------------------------------------------*/

void svg_attr_value (char *attribute, char *value)
{   
   svg_indent();
   fprintf(svgFile, "%s=\"%s\"\n", attribute, value);
}

/*---------------------------------------------------------------------
  svg_attr_values ()
  
  Prints a string and a bunch of numbers / strings as a XML attribute 
  value pair i.e. foo="0 10 1.0 5.3 bar"

  This function is derived from an example in 
  "The C Programming Language" by Kernighan and Ritchie.
  
  ---------------------------------------------------------------------*/

void svg_attr_values (char *attribute, char *format, ...)
{
   va_list ap;
   char *p, *sval;
   int ival;
   double dval;

   svg_indent();
   fprintf(svgFile, "%s=\"", attribute);
   va_start(ap, format);
   for(p=format; *p; p++){
      if(*p != '%'){
         fprintf(svgFile, "%c", *p);
         continue;
      }
      switch(*++p){
      case 'd':
        ival = va_arg(ap, int);
        fprintf(svgFile, "%d", ival);
        break;
      case 'f':
        dval = va_arg(ap, double);
        fprintf(svgFile, "%f", dval);
        break;
      case 's':
        sval = va_arg(ap, char *);
        fprintf(svgFile, "%s", sval);
        break;
      default:
        fprintf(svgFile, "%c", *p);
        break;
      }        
   }
   fprintf(svgFile, "\"\n");
   va_end(ap);
}

/*---------------------------------------------------------------------
  svg_close ()
  
  Used to close a XML expression, sets the indent level appropriately
  ---------------------------------------------------------------------*/

void svg_close (char *tag)
{
   svgIndent -= 2;
   svg_indent();
   if(strlen(tag) > 0){
      fprintf(svgFile, "</%s>\n", tag);
   } else {
      fprintf(svgFile, "/>\n");
   }
}

/*---------------------------------------------------------------------
  svg_general ()
  
  Used to print any text into the svgFile
  ---------------------------------------------------------------------*/

void svg_general (char *text)
{
   svg_indent();
   fprintf(svgFile, "%s", text);
}

/*---------------------------------------------------------------------
  svg_indent ()
  
  Indents properly based on the current indent level
  ---------------------------------------------------------------------*/

void svg_indent(void)
{
   short i;
   for(i=0;i<svgIndent;i++){
      fprintf(svgFile, " ");
   }
}

/*---------------------------------------------------------------------
  svg_stroke_width ()
  
  sets the stroke color based on the current color
  ---------------------------------------------------------------------*/

void svg_stroke_width(PLStream *pls)
{
   svg_indent();
   fprintf(svgFile, "stroke-width=\"%d\"\n", pls->width);
}

/*---------------------------------------------------------------------
  svg_stroke_color ()
  
  sets the stroke color based on the current color
  ---------------------------------------------------------------------*/

void svg_stroke_color(PLStream *pls)
{
   svg_indent();
   fprintf(svgFile, "stroke=\"#");
   write_hex(pls->curcolor.r);
   write_hex(pls->curcolor.g);
   write_hex(pls->curcolor.b);
   fprintf(svgFile, "\"\n");
}

/*---------------------------------------------------------------------
  svg_fill_color ()
  
  sets the fill color based on the current color
  ---------------------------------------------------------------------*/

void svg_fill_color(PLStream *pls)
{
   svg_indent();
   fprintf(svgFile, "fill=\"#");
   write_hex(pls->curcolor.r);
   write_hex(pls->curcolor.g);
   write_hex(pls->curcolor.b);
   fprintf(svgFile, "\"\n");
}

/*---------------------------------------------------------------------
  svg_fill_background_color ()
  
  sets the background fill color based on the current background color
  ---------------------------------------------------------------------*/

void svg_fill_background_color(PLStream *pls)
{
   svg_indent();
   fprintf(svgFile, "fill=\"#");
   write_hex(pls->cmap0[0].r);
   write_hex(pls->cmap0[0].g);
   write_hex(pls->cmap0[0].b);
   fprintf(svgFile, "\"\n");
}

/*---------------------------------------------------------------------
  write_hex ()
  
  writes a unsigned char as an approriately formatted hex value
  ---------------------------------------------------------------------*/

void write_hex(unsigned char val)
{
	if(val < 16){
		fprintf(svgFile, "0%X", val);
	} else {
		fprintf(svgFile, "%X", val);
	}
}

/*---------------------------------------------------------------------
  write_unicode ()
  
  writes a unicode character, appropriately formatted (i.e. &#xNNN)
  ---------------------------------------------------------------------*/

void write_unicode(PLUNICODE ucs4_char)
{
	fprintf(svgFile, "&#x%x;", ucs4_char);
}

/*---------------------------------------------------------------------
  desired_offset ()
  
  calculate the desired offset given font height and super/subscript level
  ---------------------------------------------------------------------*/

short desired_offset(short level, double ftHt)
{
   if(level > 0){
      return -level * ftHt * pow(0.6, abs(level));
   }
   else if(level < 0){
      return level * ftHt * pow(0.6, abs(level));
   }
   else{
      return 0;
   }
}

/*---------------------------------------------------------------------
  specify_font ()
  
  Note:
  We don't actually specify a font, just the fonts properties.
  The hope is that this will give the display program the freedom
  to choose the font with the glyphs that it needs to display
  the text.
  
  Known Issues:
  (1) On OS-X 10.4 with Firefox and Camino the "serif" font-family
  looks more like the "italic" font-style.
  
  ---------------------------------------------------------------------*/

void specify_font(PLUNICODE ucs4_char)
{
   fprintf(svgFile,"<tspan ");
         
   /* sans, serif, mono, script, symbol */
   
   if((ucs4_char&0x00F) == 0x000){
      fprintf(svgFile, "font-family=\"sans-serif\" ");
   } else if ((ucs4_char&0x00F) == 0x001) {
      fprintf(svgFile, "font-family=\"serif\" ");
   } else if ((ucs4_char&0x00F) == 0x002) {
      fprintf(svgFile, "font-family=\"mono-space\" ");   
   } else if ((ucs4_char&0x00F) == 0x003) {
      fprintf(svgFile, "font-family=\"cursive\" ");
   } else if ((ucs4_char&0x00F) == 0x004) {
     /* this should be symbol, but that doesn't seem to be available */
      fprintf(svgFile, "font-family=\"sans-serif\" ");
   }

   /* normal, italic, oblique */
   
   if((ucs4_char&0x0F0) == 0x000){
      fprintf(svgFile, "font-style=\"normal\" ");
   } else if ((ucs4_char&0x0F0) == 0x010) {
      fprintf(svgFile, "font-style=\"italic\" ");
   } else if ((ucs4_char&0x0F0) == 0x020) {
      fprintf(svgFile, "font-style=\"oblique\" ");   
   }

   /* normal, bold */

   if((ucs4_char&0xF00) == 0x000){
      fprintf(svgFile, "font-weight=\"normal\">");
   } else if ((ucs4_char&0xF00) == 0x100) {
      fprintf(svgFile, "font-weight=\"bold\">");
   }
}
