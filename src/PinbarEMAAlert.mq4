//+------------------------------------------------------------------+
//|                                              PinbarEMAAlert.mq4  |
//|                                  Copyright 2024, Antigravity AI  |
//|                                             https://google.com   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Antigravity AI"
#property link      "https://google.com"
#property version   "1.00"
#property strict

//--- input parameters
input int      EMA8_Period    = 8;
input int      EMA21_Period   = 21;
input double   MinPinSizePips = 5.0;     // Minimum size of the pinbar in pips
input double   MaxBodyRatio   = 0.3;     // Max ratio of body to total range (0.3 = 30%)
input double   MinWickRatio   = 2.0;     // Min ratio of long wick to body
input bool     AlertPopup     = true;
input bool     AlertSound     = true;
input bool     AlertPush      = true;

//--- global variables
datetime lastAlertTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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
   // Check only on a new bar formation (when the previous bar closes)
   if(lastAlertTime == iTime(NULL, 0, 1)) return;

   // Get Bar 1 Data (the recently closed candle)
   double high   = iHigh(NULL, 0, 1);
   double low    = iLow(NULL, 0, 1);
   double open   = iOpen(NULL, 0, 1);
   double close  = iClose(NULL, 0, 1);
   double range  = high - low;
   double body   = MathAbs(open - close);
   
   if(range <= 0) return;

   // Convert pips to points
   double minSizePoints = MinPinSizePips * 10 * Point;
   if(Digits == 3 || Digits == 5) minSizePoints = MinPinSizePips * 10 * Point; // Standard for 5-digit brokers
   else minSizePoints = MinPinSizePips * Point;

   // 1. Basic Pinbar Check
   bool isPinbar = false;
   string pinType = "";

   if(range >= minSizePoints && body <= (range * MaxBodyRatio))
   {
      double upperWick = high - MathMax(open, close);
      double lowerWick = MathMin(open, close) - low;
      
      // Bearish Pinbar (Bullish rejection - Long Upper Wick)
      if(upperWick >= (range * 0.6) && upperWick > lowerWick * MinWickRatio)
      {
         isPinbar = true;
         pinType = "Bearish (Rejection UP)";
      }
      // Bullish Pinbar (Bearish rejection - Long Lower Wick)
      else if(lowerWick >= (range * 0.6) && lowerWick > upperWick * MinWickRatio)
      {
         isPinbar = true;
         pinType = "Bullish (Rejection DOWN)";
      }
   }

   if(!isPinbar) return;

   // 2. EMA Penetration Check
   double ema8  = iMA(NULL, 0, EMA8_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
   double ema21 = iMA(NULL, 0, EMA21_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
   double prevEma8  = iMA(NULL, 0, EMA8_Period, 0, MODE_EMA, PRICE_CLOSE, 2);
   double prevEma21 = iMA(NULL, 0, EMA21_Period, 0, MODE_EMA, PRICE_CLOSE, 2);
   double prevClose = iClose(NULL, 0, 2);
   
   bool penetratesEMA8  = (high >= ema8 && low <= ema8);
   bool penetratesEMA21 = (high >= ema21 && low <= ema21);

   if(penetratesEMA8 || penetratesEMA21)
   {
      string emaMsg = "";
      string direction = "";
      
      if(penetratesEMA8) 
      {
         emaMsg = "EMA 8";
         direction = (prevClose > prevEma8) ? "from ABOVE" : "from BELOW";
      }
      if(penetratesEMA21) 
      {
         emaMsg = (emaMsg == "") ? "EMA 21" : "both EMA 8 and 21";
         if(direction == "") direction = (prevClose > prevEma21) ? "from ABOVE" : "from BELOW";
         else if(penetratesEMA8 && penetratesEMA21)
         {
            // If it penetrates both, we check if it came from above or below the general area
            direction = (prevClose > prevEma8 && prevClose > prevEma21) ? "from ABOVE" : "from BELOW";
         }
      }

      string msg = StringFormat("Pinbar Detected! Type: %s. Penetrated %s %s on %s %s", 
                                pinType, emaMsg, direction, Symbol(), TimeToString(iTime(NULL, 0, 1)));

      TriggerAlert(msg);
      lastAlertTime = iTime(NULL, 0, 1);
   }
}

//+------------------------------------------------------------------+
//| Trigger the configured alerts                                    |
//+------------------------------------------------------------------+
void TriggerAlert(string message)
{
   if(AlertPopup) Alert(message);
   if(AlertPush)  SendNotification(message);
   if(AlertSound) PlaySound("alert.wav");
   
   Print(message);
}
//+------------------------------------------------------------------+
