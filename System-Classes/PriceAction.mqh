//+------------------------------------------------------------------+
//|                                                  PriceAction.mqh |
//|                                   Copyright 2020, Dave Hawthorne |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Dave Hawthorne"
#property version   "1.00"
#property description "PriceAction"

class PriceAction
{
   private:
      double ask;
      double bid;
   
   public:
      PriceAction();
     ~PriceAction();
      void updateAskBid();
      double getAsk();
      double getBid();
      double getCurrentPrice();
};
//+------------------------------------------------------------------+
//| Default Constructor
//+------------------------------------------------------------------+
PriceAction::PriceAction()
{   
}
//+------------------------------------------------------------------+
//| Return the current ask price
//+------------------------------------------------------------------+
void PriceAction::updateAskBid(void)
{
   //ASK(BUY) price
   ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   //BID(SELL) price
   bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
}
//+------------------------------------------------------------------+
//| Return the current ask price
//+------------------------------------------------------------------+
double PriceAction::getAsk(void)
{
   return ask;
}
//+------------------------------------------------------------------+
//| Return the current bid price
//+------------------------------------------------------------------+
double PriceAction::getBid(void)
{
   return bid;
}
//+------------------------------------------------------------------+
//| Return the current price
//+------------------------------------------------------------------+
double PriceAction::getCurrentPrice(void)
{
   //ASK BID average
   return (ask + bid) / 2;
}
//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
PriceAction::~PriceAction()
{
}
//+------------------------------------------------------------------+
