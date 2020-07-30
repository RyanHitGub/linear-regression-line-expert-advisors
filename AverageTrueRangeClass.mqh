//+------------------------------------------------------------------+
//|                                        AverageTrueRangeClass.mqh |
//|                                   Copyright 2020, Dave Hawthorne |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Dave Hawthorne"
#property version   "1.00"
#property description "AverageTrueRangeClass"

class AverageTrueRangeClass
{
   private:
      int handler_ATR;
      double buffer_ATR[];
   
   public:
      AverageTrueRangeClass();
      void SetupATR(int period);
      void UpdateATR_Buffers();
      double getBuffer_ATR(int shift);
     ~AverageTrueRangeClass();
};
//+------------------------------------------------------------------+
//| Default Constructor
//+------------------------------------------------------------------+
AverageTrueRangeClass::AverageTrueRangeClass()
{
}
//+------------------------------------------------------------------+
//| Setup the indicator handler and set array as a timeseries
//+------------------------------------------------------------------+
void AverageTrueRangeClass::SetupATR(int period)
{
   handler_ATR = iATR(Symbol(), PERIOD_CURRENT, period);
   
   ArraySetAsSeries(buffer_ATR, true);
}
//+------------------------------------------------------------------+
//| Update the ATR buffers with the most current information
//+------------------------------------------------------------------+
void AverageTrueRangeClass::UpdateATR_Buffers(void)
{
   CopyBuffer(handler_ATR, 0, 0, 100, buffer_ATR);
}
//+------------------------------------------------------------------+
//| Return the buffer of ATR
//+------------------------------------------------------------------+
double AverageTrueRangeClass::getBuffer_ATR(int shift)
{
   return buffer_ATR[shift];
}
//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
AverageTrueRangeClass::~AverageTrueRangeClass()
{
}
//+------------------------------------------------------------------+
