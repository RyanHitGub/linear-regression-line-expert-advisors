//+------------------------------------------------------------------+
//|                                        LinearRegressionClass.mqh |
//|                                       Copyright 2020, Ryan Smith |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Ryan Smith"
#property version   "1.00"
#property description "LinearRegressionClass"

#include <Project Classes\ChandelierExitClass.mqh>

class LinearRegressionClass
{
   private:
      int handler_LR;
      double buffer_LR[];
      int period;
      double linearRegressionSlope;
      
   public:
      LinearRegressionClass();
      LinearRegressionClass(int p);
      void SetupLR();
      void UpdateLR_Buffers();
      bool DetermineSlopeLessThan(double maxSlope);
      bool DetermineSlopeGreaterThan(double minSlope, bool longTrend, bool shortTrend);
      double getLinearRegressionSlope();
     ~LinearRegressionClass();
};
//+------------------------------------------------------------------+
//| Default Constructor
//+------------------------------------------------------------------+
LinearRegressionClass::LinearRegressionClass()
{
}
//+------------------------------------------------------------------+
//| Constructor
//+------------------------------------------------------------------+
LinearRegressionClass::LinearRegressionClass(int p)
{
   period = p;
}
//+------------------------------------------------------------------+
//| Setup the indicator handler and set array as a timeseries
//+------------------------------------------------------------------+
void LinearRegressionClass::SetupLR()
{
   handler_LR = iCustom(Symbol(), PERIOD_CURRENT, "Project Indicators\\RS_LinearRegression", period);
   
   ArraySetAsSeries(buffer_LR, true);
}
//+------------------------------------------------------------------+
//| Update the LR buffers with the most current information
//+------------------------------------------------------------------+
void LinearRegressionClass::UpdateLR_Buffers(void)
{
   CopyBuffer(handler_LR, 0, 0, 100, buffer_LR);
}
//+------------------------------------------------------------------+
//Determine slope of Linear Regression line is less than max slope
//+------------------------------------------------------------------+
bool LinearRegressionClass::DetermineSlopeLessThan(double maxSlope)
{
   //Slope distance is calculated in either direction
   linearRegressionSlope = 10000 * MathAbs(buffer_LR[0] - buffer_LR[period - 1]);
   
   if(linearRegressionSlope < maxSlope)
   {
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//Determine slope of Linear Regression line is greater than min slope
//+------------------------------------------------------------------+
bool LinearRegressionClass::DetermineSlopeGreaterThan(double minSlope, bool longTrend, bool shortTrend)
{
   if(longTrend)
   {
      //Look for downward linear regression line slope when trending long
      linearRegressionSlope = 10000 * (buffer_LR[period - 1] - buffer_LR[0]);
      
      if(linearRegressionSlope > minSlope)
      {
         return true;
      }
   }
   else if(shortTrend)
   {
      //Look for upward linear regression line slope when trending short
      linearRegressionSlope = 10000 * (buffer_LR[0] - buffer_LR[period - 1]);
      
      if(linearRegressionSlope > minSlope)
      {
         return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
double LinearRegressionClass::getLinearRegressionSlope(void)
{
   return linearRegressionSlope;
}
//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
LinearRegressionClass::~LinearRegressionClass()
{
}
//+------------------------------------------------------------------+
