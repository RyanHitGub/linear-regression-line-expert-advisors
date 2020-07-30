//+------------------------------------------------------------------+
//|                          Linear Regression Contrarian System.mq5 |
//|                                       Copyright 2020, Ryan Smith |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Ryan Smith"
#property version   "1.00"
#property description "Linear Regression Contrarian System"

//===============================================
//LIBRARIES

#include <Trade/Trade.mqh>
#include <Project Classes/PriceAction.mqh>
#include <Project Classes/ChandelierExitClass.mqh>
#include <Project Classes/LinearRegressionClass.mqh>
#include <Project Classes/AverageTrueRangeClass.mqh>

//===============================================
//INDICATORS

//Chandelier Exit
input group "Chandelier Exit Indicator";
input ENUM_TIMEFRAMES higherTimeframe = PERIOD_D1;
input int period_CE_ATR = 22;
input double multiplier_CE_ATR = 3.0;

//Linear Regression
input group "Linear Regression Indicator";
input int period_LR = 10;

//ATR
input group "Average True Range Indicator";
input int period_ATR = 4;

//===============================================
//CLASSES

CTrade trade;
PriceAction classPA;
ChandelierExitClass classCE(higherTimeframe);
LinearRegressionClass classLR(period_LR);
AverageTrueRangeClass classATR();

//===============================================
//EA INPUTS

input group "Lot Size";
input double initial_LotSize = 1;

input group "Trade Entry Criteria";
input double minLinearRegressionSlope = 70;

input group "Trade Criteria - Pips or ATR";
input bool stopLoss_Pips_True_ATR_False = true;
input bool takeProfit_Pips_True_ATR_False = true;
input bool breakEven_Pips_True_ATR_False = true;
input bool trailStop_Pips_True_ATR_False = true;
input bool trailStep_Pips_True_ATR_False = true;

input group "Stop Loss";
input double stopLoss_Pips = 70;
input double stopLoss_ATR = 1;

input group "Take Profit";
input double takeProfit_Pips = 150;
input double takeProfit_ATR = 1;

input group "Break Even";
input double breakEven_Pips = 70;
input double breakEven_ATR = 1;

input group "Trail Stop";
input bool activate_TrailStop = false;
input double trailStop_Pips = 10;
input double trailStop_ATR = 1;

input group "Trail Step";
input double trailStep_Pips = 5;
input double trailStep_ATR = 1;

input group "Double Down Strategy"
input double lotSize_Multiplier = 2;
input int consecutive_Losses_Before_Multiplying = 1; 

//===============================================
//VARIABLES

double initialLotSize;
//Contains updated lotSize value
double lotSize;

//DoubleDownOnLosses variables
double lotSizeMultiplier = 0;
int consecutiveLosses = 0;
int amountOfMultipliers = 0;
ulong dealTicket_DoubleDown = 0;

//StopLossBreakEven variables
bool stopLossIsBreakEven = false;
double breakEvenPrice;

//TrailStop variables
bool stopLossIsTrailStop = false;
double buyStopLossChecker = 0;
double sellStopLossChecker = 0;

//PipsOrATRSelector variables
double stopLoss, takeProfit, breakEven, trailStop, trailStep;

//===============================================
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Check user inputs for invalid settings
   CheckInvalidInputs();
   lotSize = initialLotSize;
   
   //Setup indicators
   classCE.SetupCE(period_CE_ATR, multiplier_CE_ATR, period_CE_ATR);
   classLR.SetupLR();
   classATR.SetupATR(period_ATR);   

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //Update ASK and BID
   classPA.updateAskBid();
   
   //Update indicator buffers
   classCE.UpdateCE_Buffers();
   classLR.UpdateLR_Buffers();
   classATR.UpdateATR_Buffers(); 
   
   //Using Pips or updated ATR values
   PipsOrATRSelector();  
   
   //Move STOP LOSS to BREAK EVEN
   StopLossBreakEven();
   
   //Enable TRAIL STOP LOSS
   if(stopLossIsBreakEven && activate_TrailStop)
   {
      TrailStop();
   }

   //Update LOTSIZE once trade deals occur
   DoubleDownOnLosses();
   
   //Higher timeframe is trending LONG or SHORT
   classCE.DetermineMainTrend();
   
   Comment("CE:   " + "\n" + 
           "Main trend LONG:    " + string(classCE.getMainTrend_Long()) + "        Main trend SHORT:    " + string(classCE.getMainTrend_Short()) + "\n\n" +
           
           "LR:   " + "\n" +
           "Slope (" + string(minLinearRegressionSlope) + "):    " + string(classLR.DetermineSlopeGreaterThan(minLinearRegressionSlope, classCE.getMainTrend_Long(), classCE.getMainTrend_Short())) + 
           "        Slope:    " + string(NormalizeDouble(classLR.getLinearRegressionSlope(), 4)) + "\n\n" + 
           
           "Consecutive Losses:    " + string(consecutiveLosses) + "        Lot Size:    " + string(lotSize)
          );
   
   if(IsNewCandle_CurrentTimeframe())
   {   
      //LONG condition
      if(classCE.getMainTrend_Long() && 
         iClose(Symbol(), PERIOD_CURRENT, 1) > classCE.getBuffer_CE_InnerLong(0) &&
         classLR.DetermineSlopeGreaterThan(minLinearRegressionSlope, classCE.getMainTrend_Long(), classCE.getMainTrend_Short()) &&
         !HasOpenPositions())
      {
         //Enter BUY position
         OpenLongTrade();
      }
      
      //SHORT condition
      if(classCE.getMainTrend_Short() && 
         iClose(Symbol(), PERIOD_CURRENT, 1) < classCE.getBuffer_CE_InnerShort(0) &&
         classLR.DetermineSlopeGreaterThan(minLinearRegressionSlope, classCE.getMainTrend_Long(), classCE.getMainTrend_Short()) &&
         !HasOpenPositions())
      {
         //Enter SELL position
         OpenShortTrade();
      }
   }   
}
//===============================================
//+------------------------------------------------------------------+
//Ensure the user inputs are valid
//+------------------------------------------------------------------+
void CheckInvalidInputs()
{
   // Initial LOTSIZE
   if(initial_LotSize > 0)
   {
      initialLotSize = initial_LotSize;
   }
   else
   {
      initialLotSize = 1;
   }
   
   // LOTSIZE multiplier
   if(lotSize_Multiplier > 0)
   {
      lotSizeMultiplier = lotSize_Multiplier;
   }
   else
   {
      lotSizeMultiplier = 1;
   }
}
//+------------------------------------------------------------------+
//Check if a new candle has been opened on higher timeframe
//+------------------------------------------------------------------+
bool IsNewCandle_HigherTimeframe()
{
   //Static will increase whenever the function is called
   static int barsOnHigherTimeframe = 0;
   
   //Check if the number of candles on the current symbol and higher timeframe is equal to barsOnHigherTimeframe
   if(Bars(Symbol(), higherTimeframe) == barsOnHigherTimeframe)
   {
      return(false);
   }

   //Update the current number of candles on chart to barsOnHigherTimeframe
   barsOnHigherTimeframe = Bars(Symbol(), higherTimeframe);
   return(true);
}
//+------------------------------------------------------------------+
//Check if a new candle has been opened on current timeframe
//+------------------------------------------------------------------+
bool IsNewCandle_CurrentTimeframe()
{
   static int barsOnCurrentTimeframe = 0;
   
   //Check if the number of candles on the current symbol and current timeframe is equal to barsOnCurrentTimeframe
   if(Bars(Symbol(), PERIOD_CURRENT) == barsOnCurrentTimeframe){
      return(false);
   }

   //Assign the current number of candles on chart to barsOnCurrentTimeframe
   barsOnCurrentTimeframe = Bars(Symbol(), PERIOD_CURRENT);
   return(true);
}
//+------------------------------------------------------------------+
//| Check there are no open positions so trading can commence                                              
//+------------------------------------------------------------------+
bool HasOpenPositions()
{ 
   //Get total positions (open trades)
   int positionsTotal = PositionsTotal();
   
   //System will trade when there are no open trades
   if(positionsTotal == 0)
   {
      return false;
   }
   else
   {
      return true;
   }   
}
//+------------------------------------------------------------------+
//| Open LONG trade position. BUY                                               
//+------------------------------------------------------------------+
void OpenLongTrade()
{
   //Prepare a trade request
   MqlTradeRequest tradeRequest = {0};
   tradeRequest.action = TRADE_ACTION_DEAL;
   tradeRequest.symbol = Symbol();
   tradeRequest.volume = lotSize;
   tradeRequest.sl = classPA.getAsk() - stopLoss;
   tradeRequest.tp = classPA.getAsk() + takeProfit;
   tradeRequest.type = ORDER_TYPE_BUY;
   tradeRequest.price = classPA.getAsk();
   
   //Send a trade request
   MqlTradeResult tradeResult = {0};
   bool res = OrderSend(tradeRequest, tradeResult);
}
//+------------------------------------------------------------------+
//| Open SHORT trade position. SELL                                               
//+------------------------------------------------------------------+
void OpenShortTrade()
{
   //Prepare a trade request
   MqlTradeRequest tradeRequest = {0};
   tradeRequest.action = TRADE_ACTION_DEAL;
   tradeRequest.symbol = Symbol();
   tradeRequest.volume = lotSize;
   tradeRequest.sl = classPA.getBid() + stopLoss;
   tradeRequest.tp = classPA.getBid() - takeProfit;
   tradeRequest.type = ORDER_TYPE_SELL;
   tradeRequest.price = classPA.getBid();
   
   //Send a trade request
   MqlTradeResult tradeResult = {0};
   bool res = OrderSend(tradeRequest, tradeResult);
}
//+------------------------------------------------------------------+
//| Multiply LOTSIZE when experiencing consecutive losses                                            
//+------------------------------------------------------------------+
void DoubleDownOnLosses()
{
   //Get symbol trade history
   HistorySelect(0, TimeCurrent());   
   int totalDeals = HistoryDealsTotal();

   //Count the most recent deal only once
   if(dealTicket_DoubleDown != HistoryDealGetTicket(totalDeals - 1))
   {         
      dealTicket_DoubleDown = HistoryDealGetTicket(totalDeals - 1); 
      
      //Ensure there is a valid ticket
      if(dealTicket_DoubleDown > 0)
      {    
         //Trade closed due to STOP LOSS triggered
         if(HistoryDealGetInteger(dealTicket_DoubleDown, DEAL_REASON) == DEAL_REASON_SL)
         {  
            //Do not count STOP LOSS at a BREAK EVEN price
            if(!stopLossIsBreakEven)
            {            
               consecutiveLosses++;
            }            
            stopLossIsBreakEven = false;
         }
         //Trade closed due to TAKE PROFIT triggered
         else if(HistoryDealGetInteger(dealTicket_DoubleDown, DEAL_REASON) == DEAL_REASON_TP)
         {
            //Reset DOUBLE DOWN settings    
            consecutiveLosses = 0;
            amountOfMultipliers = 0;
            lotSize = initialLotSize;
            stopLossIsBreakEven = false;
         }
      }
      
      //Apply LOTSIZE multiplier
      if(consecutiveLosses > 0)
      {     
         //Reset LOTSIZE
         lotSize = initialLotSize;
         //Number multiplier iterations
         //Truncates value to get correct iterations
         amountOfMultipliers = consecutiveLosses / consecutive_Losses_Before_Multiplying;

         //Multiplier iterations
         for(int i = 0; i < amountOfMultipliers; i++)
         {                  
            //Multiply LOTSIZE
            lotSize *= lotSizeMultiplier;
            //Trade volume is invalid with excess decimal points
            lotSize = NormalizeDouble(lotSize, 2);
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Adjust STOP LOSS to BREAK EVEN                                              
//+------------------------------------------------------------------+
void StopLossBreakEven()
{   
   //Get total positions (open trades)
   int positionsTotal = PositionsTotal();
   
   //Loop through all open trades
   for(int i = positionsTotal; i >= 0; i--)
   {
      //Current ticket
      ulong ticket = PositionGetTicket(i);
      
      //Access position data based on ticket
      if(PositionSelectByTicket(ticket))
      {
         //If a BUY position and has moved the desired distance towards TAKE PROFIT
         if(PositionGetInteger(POSITION_TYPE) == 0 && PositionGetDouble(POSITION_PRICE_CURRENT) >= PositionGetDouble(POSITION_PRICE_OPEN) + breakEven)
         {
            //TAKE PROFIT and STOP LOSS modifications
            double buyTakeProfit = PositionGetDouble(POSITION_TP);
            double buyStopLoss = PositionGetDouble(POSITION_PRICE_OPEN) + 0.0001;

            //Modify once
            if(!stopLossIsBreakEven)
            {
               //Modify selected trade
               trade.PositionModify(ticket, buyStopLoss, buyTakeProfit);
               //STOP LOSS has been moved to BREAK EVEN
               stopLossIsBreakEven = true;
               //The BREAK EVEN price required for TRAIL STOP functionality
               breakEvenPrice = PositionGetDouble(POSITION_PRICE_OPEN) + breakEven;
            }   
         }
         //If a SELL position and has moved the desired distance towards TAKE PROFIT
         else if(PositionGetInteger(POSITION_TYPE) == 1 && PositionGetDouble(POSITION_PRICE_CURRENT) <= PositionGetDouble(POSITION_PRICE_OPEN) - breakEven)
         {
            double sellTakeProfit = PositionGetDouble(POSITION_TP);
            double sellStopLoss = PositionGetDouble(POSITION_PRICE_OPEN) - 0.0001;

            if(!stopLossIsBreakEven)
            {
               trade.PositionModify(ticket, sellStopLoss, sellTakeProfit);
               stopLossIsBreakEven = true;
               breakEvenPrice = PositionGetDouble(POSITION_PRICE_OPEN) - breakEven;
            }
         }       
      }
   }
}
//+------------------------------------------------------------------+
//| Set a TRAIL STOP LOSS                                              
//+------------------------------------------------------------------+
void TrailStop()
{   
   //Get total positions (open trades)
   int positionsTotal = PositionsTotal();
   
   //Loop through all open trades
   for(int i = positionsTotal; i >= 0; i--)
   {
      //Current ticket
      ulong ticket = PositionGetTicket(i);
      
      //Access position data based on ticket
      if(PositionSelectByTicket(ticket))
      {
         //If a BUY position and has moved the desired distance further than BREAK EVEN towards TAKE PROFIT
         //and do not move the TRAIL STOP below its previous price
         if(PositionGetInteger(POSITION_TYPE) == 0 && 
            PositionGetDouble(POSITION_PRICE_CURRENT) >= breakEvenPrice + trailStop && 
            PositionGetDouble(POSITION_PRICE_CURRENT) - trailStep > PositionGetDouble(POSITION_SL))
         {
            //TAKE PROFIT and STOP LOSS modifications
            double buyTakeProfit = PositionGetDouble(POSITION_TP);
            double buyStopLoss = PositionGetDouble(POSITION_PRICE_CURRENT) - trailStep;

            //Modify once
            if(buyStopLoss != buyStopLossChecker)
            {
               //Modify selected trade
               trade.PositionModify(ticket, buyStopLoss, buyTakeProfit);
               buyStopLossChecker = buyStopLoss;      
            }   
         }
         //If a SELL position and has moved the desired distance further than BREAK EVEN towards TAKE PROFIT
         //and do not move the TRAIL STOP above its previous price
         else if(PositionGetInteger(POSITION_TYPE) == 1 && 
                 PositionGetDouble(POSITION_PRICE_CURRENT) <= breakEvenPrice - trailStop &&
                 PositionGetDouble(POSITION_PRICE_CURRENT) + trailStep < PositionGetDouble(POSITION_SL))
         {
            double sellTakeProfit = PositionGetDouble(POSITION_TP);
            double sellStopLoss = PositionGetDouble(POSITION_PRICE_CURRENT) + trailStep;

            if(sellStopLoss != sellStopLossChecker)
            {
               trade.PositionModify(ticket, sellStopLoss, sellTakeProfit);
               sellStopLossChecker = sellStopLoss;
            }
         }       
      }
   }
}
//+------------------------------------------------------------------+
//| Determine Pips or ATR for STOP LOSS, TAKE PROFIT, BREAK EVEN,
//| TRAIL STOP, and TRAIL STEP                                             
//+------------------------------------------------------------------+
void PipsOrATRSelector()
{
   //Set STOP LOSS as Pips or ATR
   if(stopLoss_Pips_True_ATR_False == true)
   {
      stopLoss = stopLoss_Pips / 10000;
   }
   else
   {
      stopLoss = classATR.getBuffer_ATR(0) * stopLoss_ATR;
   }
   
   //Set TAKE PROFIT as Pips or ATR
   if(takeProfit_Pips_True_ATR_False == true)
   {
      takeProfit = takeProfit_Pips / 10000;
   }
   else
   {
      takeProfit = classATR.getBuffer_ATR(0) * takeProfit_ATR;
   }
   
   //Set BREAK EVEN as Pips or ATR
   if(breakEven_Pips_True_ATR_False == true)
   {
      breakEven = breakEven_Pips / 10000;
   }
   else
   {
      breakEven = classATR.getBuffer_ATR(0) * breakEven_ATR;
   }

   //Set TRAIL STOP as Pips or ATR
   if(trailStop_Pips_True_ATR_False == true)
   {
      trailStop = trailStop_Pips / 10000;
   }
   else
   {
      trailStop = classATR.getBuffer_ATR(0) * trailStop_ATR;
   }

   //Set TRAIL STEP as Pips or ATR
   if(trailStep_Pips_True_ATR_False == true)
   {
      trailStep = trailStep_Pips / 10000;
   }
   else
   {
      trailStep = classATR.getBuffer_ATR(0) * trailStep_ATR;
   } 
}