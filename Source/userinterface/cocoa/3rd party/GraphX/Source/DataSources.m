#import "DataSources.h"

@implementation DataSources

- (void)windowWillClose:(NSNotification *)aNotification
{
  [NSApp terminate:self];
}


//************Curve DataSource
- (double)yValueForXValue:(double)x
{
//  if( (x > -2 && x < -1) || (x > 1 && x < 2) )
//  return INFINITY;
//  if (x > -.5 && x < .5)
//  return NAN;
//  if(YES)
//  return sin(x);
  return x*x*x;
}

//************Histogram DataSource
 - (float)frequencyForBucketWithLowerBound:(float)lowerBound andUpperLimit:(float)upperLimit;
{
  if (NO)
    return 0.0f;
  else
    return .398942*exp(-.5*pow(((lowerBound + upperLimit)/2-5)/1.5,2))*24;
  //return pow((upperLimit-5),2) + 50;
}


//************ScatterPlot DataSource
- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index
{
  int factor = 8;
  int variablility = 10;
  
  float x = (float)index*10/factor;
  float y = 10*((float)(Random()%variablility)+index*index+variablility*.75)/(1.75*variablility+factor*factor);
  
  
//  if( (x > -2 && x < -1) || (x > 1 && x < 2) )
//  y = INFINITY;
//  else if (x > -.5 && x < .5)
//  y = NAN;
//  else
//  y = cos(x);
  
  
  *(*point) = NSMakePoint(x, y);
  
  
  if(index > factor)
    *point = nil;
}

@end
