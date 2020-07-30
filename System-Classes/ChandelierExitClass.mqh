//+------------------------------------------------------------------+
//|                                          ChandelierExitClass.mqh |
//|                                   Copyright 2020, Dave Hawthorne |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Dave Hawthorne"
#property version   "1.00"
#property description "ChandelierExitClass"

class ChandelierExitClass
{
   private:
      int handler_CE;
      double buffer_CE_InnerLong[];
      double buffer_CE_InnerShort[];
      bool mainTrend_Long;
      bool mainTrend_Short;
      double distance_CP_CE;
      double distance_CP_DailyHighLow;
      ENUM_TIMEFRAMES timeframe;
   
   public:
      ChandelierExitClass();
      ChandelierExitClass(ENUM_TIMEFRAMES t);
      void SetupCE(int period, double multiplier, int lookBackPeriod);
      void UpdateCE_Buffers();
      void DetermineMainTrend();
      bool DetermineDistanceCurrentPriceChandelierExit(int distance, double currentPrice);
      bool DetermineDistanceCurrentPriceDailyHighLow(int distance, double currentPrice);
      double getBuffer_CE_InnerLong(int shift);
      double getBuffer_CE_InnerShort(int shift);
      bool getMainTrend_Long();
      bool getMainTrend_Short();
      double getDistance_CP_CE();
      double getDistance_CP_DailyHighLow();
     ~ChandelierExitClass();
};
//+------------------------------------------------------------------+
//| Default Constructor
//+------------------------------------------------------------------+
ChandelierExitClass::ChandelierExitClass()
{
}//+------------------------------------------------------------------+
//| Constructor
//+------------------------------------------------------------------+
ChandelierExitClass::ChandelierExitClass(ENUM_TIMEFRAMES t)
{
   timeframe = t;
}
//+------------------------------------------------------------------+
//| Setup the indicator handler and set array as a timeseries
//+------------------------------------------------------------------+
void ChandelierExitClass::SetupCE(int period, double multiplier, int lookBackPeriod)
{
   handler_CE = iCustom(Symbol(), timeframe, "Project Indicators\\Chandelier_Exit", period, multiplier, 0, lookBackPeriod);
   
   ArraySetAsSeries(buffer_CE_InnerLong, true);
   ArraySetAsSeries(buffer_CE_InnerShort, true); 
}
//+------------------------------------------------------------------+
//| Update the CE buffers with the most current information
//+------------------------------------------------------------------+
void ChandelierExitClass::UpdateCE_Buffers(void)
{
   CopyBuffer(handler_CE, 0, 0, 100, buffer_CE_InnerLong);
   CopyBuffer(handler_CE, 1, 0, 100, buffer_CE_InnerShort);
}
//+------------------------------------------------------------------+
//| Determine the main trend of the higher timeframe
//+------------------------------------------------------------------+
void ChandelierExitClass::DetermineMainTrend(void)
{
   //When buffer is inactive it stores a large value (counter-intuitive)
   if(buffer_CE_InnerLong[0] < buffer_CE_InnerShort[0])
   {
      //Trending LONG
      mainTrend_Short = false;
      mainTrend_Long = true;
   }
   else if(buffer_CE_InnerLong[0] > buffer_CE_InnerShort[0])
   {
      //Trending SHORT
      mainTrend_Long = false;
      mainTrend_Short = true;
   }
}
//+------------------------------------------------------------------+
//Determine the distance of current price and the chandelier exit channels
//+------------------------------------------------------------------+
bool ChandelierExitClass::DetermineDistanceCurrentPriceChandelierExit(int distance, double currentPrice)
{
   if(mainTrend_Long)
   {
      //Distance of current price above long buffer
      distance_CP_CE = 10000 * (currentPrice - buffer_CE_InnerLong[0]);
      
      if(distance_CP_CE > distance)
      {
         return true;
      }
   }
   else if(mainTrend_Short)
   {
      //Distance of current price below short buffer
      distance_CP_CE = 10000 * (buffer_CE_InnerShort[0] - currentPrice);
   
      if(distance_CP_CE > distance)
      {
         return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//Determine the distance of current price and the chandelier exit channels
//+------------------------------------------------------------------+
bool ChandelierExitClass::DetermineDistanceCurrentPriceDailyHighLow(int distance, double currentPrice)
{
   if(mainTrend_Long)
   {
      //Distance of current price below previous day high
      distance_CP_DailyHighLow = 10000 * (iHigh(Symbol(), timeframe, 1) - currentPrice);
      
      if(distance_CP_DailyHighLow > distance)
      {
         return true;
      }
   }
   else if(mainTrend_Short)
   {
      //Distance of current price above previous day low
      distance_CP_DailyHighLow = 10000 * (currentPrice - iLow(Symbol(), timeframe, 1));

      if(distance_CP_DailyHighLow > distance)
      {
         return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
//| Return the inner long buffer of Chandelier Exit
//+------------------------------------------------------------------+
double ChandelierExitClass::getBuffer_CE_InnerLong(int shift)
{
   return buffer_CE_InnerLong[shift];
}
//+------------------------------------------------------------------+
//| Return the inner short buffer of Chandelier Exit
//+------------------------------------------------------------------+
double ChandelierExitClass::getBuffer_CE_InnerShort(int shift)
{
   return buffer_CE_InnerShort[shift];
}
//+------------------------------------------------------------------+
//| Return main trend long
//+------------------------------------------------------------------+
bool ChandelierExitClass::getMainTrend_Long(void)
{
   return mainTrend_Long;
}
//+------------------------------------------------------------------+
//| Return main trend short
//+------------------------------------------------------------------+
bool ChandelierExitClass::getMainTrend_Short(void)
{
   return mainTrend_Short;
}
//+------------------------------------------------------------------+
//| Return the distance of the current price and chandelier exit buffers
//+------------------------------------------------------------------+
double ChandelierExitClass::getDistance_CP_CE(void)
{
   return distance_CP_CE;
}
//+------------------------------------------------------------------+
//| Return the distance of the current price and daily high/low
//+------------------------------------------------------------------+
double ChandelierExitClass::getDistance_CP_DailyHighLow(void)
{
   return distance_CP_DailyHighLow;
}
//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
ChandelierExitClass::~ChandelierExitClass()
{
}
//+------------------------------------------------------------------+