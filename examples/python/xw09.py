from Numeric import *
from pl import *

XPTS = 35
YPTS = 46
XSPA = 2./(XPTS-1)
YSPA = 2./(YPTS-1)
#polar plot data
PERIMETERPTS = 100
RPTS = 40
THETAPTS = 40

#potential plot data
PPERIMETERPTS = 100
PRPTS = 40
PTHETAPTS = 64

tr = array((XSPA, 0.0, -1.0, 0.0, YSPA, -1.0))

def mypltr(x, y):
    global tr
    result0 = tr[0] * x + tr[1] * y + tr[2]
    result1 = tr[3] * x + tr[4] * y + tr[5]
    return array((result0, result1))

def polar():
    #polar contour plot example.
    plenv(-1., 1., -1., 1., 0, -2,)
    plcol0(1)

    # Perimeter
    t = (2.*pi/(PERIMETERPTS-1))*arange(PERIMETERPTS)
    px = cos(t)
    py = sin(t)
    plline(px, py)
    
    # create data to be contoured.
    r = arange(RPTS)/float(RPTS-1)
    r.shape = (-1,1)
    theta = (2.*pi/float(THETAPTS-1))*arange(THETAPTS)
    xg = r*cos(theta)
    yg = r*sin(theta)
    zg = r*ones(THETAPTS)

    lev = 0.05 + 0.10*arange(10)
    
    plcol0(2)
    plcont( zg, lev, "pltr2", xg, yg, 2 )
    #                                 ^-- :-).  Means: "2nd coord is wrapped."
    plcol0(1)
    pllab("", "", "Polar Contour Plot")

def potential():
    #shielded potential contour plot example.

    # create data to be contoured.
    r = 0.5 + arange(PRPTS)
    r.shape = (-1,1)
    theta = (2.*pi/float(PTHETAPTS))*(0.5+arange(PTHETAPTS))
    xg = r*cos(theta)
    yg = r*sin(theta)

    rmax = max(r.flat)
    xmin = min(xg.flat)
    xmax = max(xg.flat)
    ymin = min(yg.flat)
    ymax = max(yg.flat)
    x0 = (xmin + xmax)/2.
    y0 = (ymin + ymax)/2.
    #perturbed (expanded) limits

    peps = 0.05
    xpmin = xmin - abs(xmin)*peps
    xpmax = xmax + abs(xmax)*peps
    ypmin = ymin - abs(ymin)*peps
    ypmax = ymax + abs(ymax)*peps


    # Potential inside a conducting cylinder (or sphere) by method of images.
    # Charge 1 is placed at (d1, d1), with image charge at (d2, d2).
    # Charge 2 is placed at (d1, -d1), with image charge at (d2, -d2).
    # Also put in smoothing term at small distances.

    eps = 2.

    q1 = 1.
    d1 = rmax/4.

    q1i = - q1*rmax/d1
    d1i = rmax**2/d1

    q2 = -1.
    d2 = rmax/4.

    q2i = - q2*rmax/d2
    d2i = rmax**2/d2

    div1 = sqrt((xg-d1)**2 + (yg-d1)**2 + eps**2)
    div1i = sqrt((xg-d1i)**2 + (yg-d1i)**2 + eps**2)

    div2 = sqrt((xg-d2)**2 + (yg+d2)**2 + eps**2)
    div2i = sqrt((xg-d2i)**2 + (yg+d2i)**2 + eps**2)

    zg = q1/div1 + q1i/div1i + q2/div2 + q2i/div2i

    zmin = min(zg.flat)
    zmax = max(zg.flat)
    #print q1, d1, q1i, d1i, q2, d2, q2i, d2i
    #print xmin, xmax, ymin, ymax, zmin, zmax

    # Positive and negative contour levels.
    nlevel = 20
    dz = (zmax-zmin)/float(nlevel)
    clevel = zmin + (arange(20)+0.5)*dz
    clevelpos = compress(clevel > 0., clevel)
    clevelneg = compress(clevel <= 0., clevel)
    
    #Colours!
    ncollin = 11
    ncolbox = 1
    ncollab = 2
		      
    #Finally start plotting this page!
    pladv(0)
    plcol0(ncolbox)

    plvpas(0.1, 0.9, 0.1, 0.9, 1.0)
    plwind(xpmin, xpmax, ypmin, ypmax)
    plbox("", 0., 0, "", 0., 0)

    plcol0(ncollin)
    # Negative contours
    pllsty(2)
    plcont( zg, clevelneg, "pltr2", xg, yg, 2 )

    # Positive contours
    pllsty(1)
    plcont( zg, clevelpos, "pltr2", xg, yg, 2 )


    # Draw outer boundary
    t = (2.*pi/(PPERIMETERPTS-1))*arange(PPERIMETERPTS)
    px = x0 + rmax*cos(t)
    py = y0 + rmax*sin(t)

    plcol0(ncolbox)
    plline(px, py)
    
    plcol0(ncollab)
    pllab("", "", "Shielded potential of charges in a conducting sphere")

def main():

    mark = 1500
    space = 1500
    
    clevel = -1. + 0.2*arange(11)

    xx = (arrayrange(XPTS) - XPTS/2) / float((XPTS/2))
    yy = (arrayrange(YPTS) - YPTS/2) / float((YPTS/2)) - 1.
    xx.shape = (-1,1)
    z = (xx*xx)-(yy*yy)
    # 2.*outerproduct(xx,yy) for new versions of Numeric which have outerproduct.
    w = 2.*xx*yy

    # Set up grids.

    xg0 = zeros(XPTS,"double")
    yg0 = zeros(YPTS,"double")
    # Note *for the given* tr, mypltr(i,j)[0] is only a function of i
    # and mypltr(i,j)[1] is only function of j.
    for i in range(XPTS):
	xg0[i] = mypltr(i,0)[0]
    for j in range(YPTS):
	yg0[j] = mypltr(0,j)[1]

    distort = 0.4
    cos_x = cos((pi/2.)*xg0)
    cos_y = cos((pi/2.)*yg0)
    xg1 = xg0 + distort*cos_x
    yg1 = yg0 - distort*cos_y
    #Essential to copy (via slice) rather than assign by reference.
    xg0t = xg0[:]
    cos_x.shape = (-1,1)
    xg0t.shape = (-1,1)
    xg2 = xg0t + distort*cos_x*cos_y
    yg2 = yg0 - distort*cos_x*cos_y
	    
    # Plot using mypltr (scaled identity) transformation used to create
    # xg0 and yg0
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr1", xg0, yg0, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr1", xg0, yg0, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

    pl_setcontlabelparam(0.006, 0.3, 0.1, 1)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr1", xg0, yg0, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr1", xg0, yg0, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

    # Plot using 1D coordinate transformation.
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr1", xg1, yg1, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr1", xg1, yg1, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

    pl_setcontlabelparam(0.006, 0.3, 0.1, 1)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr1", xg1, yg1, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr1", xg1, yg1, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

    # Plot using 2D coordinate transformation.
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr2", xg2, yg2, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr2", xg2, yg2, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

    pl_setcontlabelparam(0.006, 0.3, 0.1, 1)
    plenv(-1.0, 1.0, -1.0, 1.0, 0, 0)
    plcol0(2)
    plcont( z, clevel, "pltr2", xg2, yg2, 0 )
    plstyl( 1, mark, space )
    plcol0(3)
    plcont( w, clevel, "pltr2", xg2, yg2, 0 )
    plstyl( 0, mark, space )
    plcol0(1)
    pllab("X Coordinate", "Y Coordinate", "Streamlines of flow");

#   polar contour examples.
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)
    polar()
    pl_setcontlabelparam(0.006, 0.3, 0.1, 1)
    polar()

#   potential contour examples.
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)
    potential()
    pl_setcontlabelparam(0.006, 0.3, 0.1, 1)
    potential()

# Restore defaults
    plcol0(1)
    pl_setcontlabelparam(0.006, 0.3, 0.1, 0)

main()
