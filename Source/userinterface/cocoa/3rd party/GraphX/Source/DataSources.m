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
  return x * x * x;
}

- (NSInteger)numberOfSeries
{
    return 2;
}

//************Histogram DataSource
- (float)frequencyForBucket:(NSUInteger)index label:(NSString**)outLabel inSeries:(NSInteger)series
{
    if (NO)
        return 8.0f;

    *outLabel = [NSString stringWithFormat:@"%lu", (unsigned long)index];

    //return .398942 * exp(-.5 * pow(((index / 10.0f) / 2 - 5) / 1.5, 2)) * 24;
    //return pow((upperLimit-5),2) + 50;
    return (series = 0) ? 0.9 * index : 0.6 * index;
}


//************ScatterPlot DataSource
- (void)getPoint:(NSPointPointer *)point atIndex:(unsigned)index inSeries:(NSInteger)series
{
  int factor = 10000;
  int variablility = 100;
  const double xMax = 10.0;
  
  float x = (float)index * xMax / factor;
  float y = 10 * ((float)(random() % variablility) + index * index + variablility * .75) / (1.75 * variablility + factor * factor);
  
  if (series == 1)
    y *= 0.67;
  
//  if( (x > -2 && x < -1) || (x > 1 && x < 2) )
//  y = INFINITY;
//  else if (x > -.5 && x < .5)
//  y = NAN;
//  else
//  y = cos(x);
  
  *(*point) = NSMakePoint(x, y);
  
  if (index > factor)
    *point = nil;
}

@end
