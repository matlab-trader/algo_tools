function [orderId,ibConnectionObject,contract,order,errMsg] = IBC(varargin)
%IBC - Get data from or place a trade order to InteractiveBrokers via the IB TWS
%
% INPUTS:
%
%   varargin = Matlab struct or CSV/XLS filename or fieldname/value pairs, with the following optional fields:
%
%       General data:
%          LogFileName      (String) (default='./IB_tradeslog_YYYYMMDD.csv')
%          MsgDisplayLevel  (Number) (default=0; one of -2=most verbose; -1=display all messages & events; 0=display all messages (but not events), 1=only display errors, 2=display nothing)
%
%       Connection:
%          ClientId         (Number) (default=random; an integer value specifying the client ID)
%          Host             (String) (dafault='localhost' = '127.0.0.1' = local computer; IP address of the computer that runs TWS/Gateway)
%          Port             (Number) (default=7496; an integer value specifying the port number used by TWS/Gateway)
%             Note: IBC will always use the last Port value specified, so if you are using this parameter to
%                   control two separate TWS/Gateway apps at the same time, be sure to specify the Port for each action,
%                   otherwise it might get sent to the wrong TWS/Gateway app!
%          AccountName      (String) (default=''; example: 'DU12345'; usable when Action=Buy,Sell,SShort,SLong,Close,Exercise,Lapse,Account,Portfolio)
%
%       Contract data (http://www.interactivebrokers.com/en/software/api/apiguide/java/contract.htm):
%          Symbol           (String) (default=''; e.g., 'EUR')
%          LocalSymbol      (String) (default=''; e.g., 'EUR.USD')
%          SecType          (String) (default='STK'; one of: STK,OPT,FUT,IND,FOP,CASH,WAR,BOND,FUND,IOPT,SSF,CMDTY,BAG,etc.)
%          Exchange         (String) (default='SMART')
%          Currency         (String) (default='USD')
%          Expiry           (String) (default=''; format:'YYYYMM')
%          Strike           (Number) (default=0.0)
%          Right            (String) (default=''; one of 'P','PUT','C','CALL')
%          Multiplier       (Number) (default=[])
%          IncludeExpired   (Number) (default=0=false; either 0 (do not consider expired options/futures), or 1 (do consider)
%          ConId            (Number) (default=[])
%          SecId            (String) (default=''; must be specified together with SecIdType)
%          SecIdType        (String) (default=''; one of 'ISIN','CUSIP'; must be specified together with SecId)
%
%       Order/query data (http://www.interactivebrokers.com/en/software/api/apiguide/java/order.htm):
%          Action           (String) (default='License'; one of Buy,Sell,SShort,SLong,Close,Exercise,Lapse,Query,Cancel,Account,Portfolio,History,Realtime,Scanner,Contract,Fundamental,License,Version,Disconnect)
%          Quantity         (Number) (default=0)
%          Type             (String) (default='LMT'; one of MKT,MKTCLS,LMT,LMTCLS,PEGMKT,STP,STPLMT,MIT,REL,TRAIL,TRAILLIMIT,TWAP,VWAP,GuarranteedVWAP,ArrivalPx,DarkIce,PctVol,BalanceImpactRisk,MinImpact etc.)
%             see: https://interactivebrokers.github.io/tws-api/basic_orders.html
%                  http://www.interactivebrokers.com/en/index.php?f=4985
%             Note: must have non-empty limitPrice otherwise IB will throw a null-pointer exception
%             Note: VWAP algo must set LimitPrice despite the fact that VWAP doesn't really need it
%             Note: OPEN can be used with Action=Query and returns the list of open orders
%             Note: when Action='Query', Type='Executions' will return the list of today's trade executions
%          TIF              (String) (default='GTC'; one of 'Day','GTC','IOC','GTD') = Time-In-Force
%          LimitPrice       (Number) (default=0)
%          AuxPrice         (Number) (default=0)
%          OCAGroup         (String) (default='') = One-Cancels-All identifier string
%          OCAType          (Number) (default=2; one of: 1=cancel with block; 2=reduce with block; 3=reduce without block)
%          ParentId         (Number) (default=0) = useful for setting child orders of a parent orderId
%          TrailingPercent  (Number) (default=0; relevant only for TRAIL order types)
%          TrailStopPrice   (Number) (default=0; relevant only for Type='TRAIL LIMIT')
%          GoodAfterTime    (String) (default=''; format: 'YYYYMMDD hh:mm:ss TMZ' [TMZ is optional])
%          GoodTillDate     (String) (default=''; format: 'YYYYMMDD hh:mm:ss TMZ' [TMZ is optional])
%          ComboActions     (Cell array of strings) (default={}) = actions for corresponding combo legs. Example: {'BUY','SELL'}
%          ComboRatios      (Numeric array) (default=[]) = relative quantity ratios for corresponding combo legs. Example: [1,1]
%          ComboBagSymbol   (String) (default='') the symbol of a combo bag order or query, useful when the underlying legs have different underlying symbols
%          BracketDelta     (Number) (default=[]) = price offset for stop-loss & take-profit BUY/SELL bracket child orders
%             Note: bracketDelta may be a single value or a [lowerDelta,upperDelta] pair of values
%             Note: value(s) must be positive: the low bracket will use limitPrice-lowerDelta, high bracket will use limitPrice+upperDelta
%          BracketTypes     (Cell array of 2 strings) (default={'STP','LMT'} for Buy, {'LMT','STP'} for Sell)
%             Types of child bracket orders: First string in the cell array defines the order type for the lower bracket, 2nd string defines order type for the upper bracket
%          TriggerMethod    (Number) (default=0; one of 0=Default, 1=Double-Bid-Ask, 2=Last, 3=Double-Last, 4=Bid-Ask, 7=Last-or-Bid-Ask, 8=Mid-point)
%          OutsideRTH       (Number) (default=0=false; either 0 (order should not execute outside regular trading hours), or 1 (it should)
%          OrderId          (Number) (default=auto-assigned; if specified, then the specified order data will be updated, rather than creating a new order)
%          Hold             (Number) (default=0=false; either 0 (immediately send Buy/Sell order to IB), or 1 (do not send immediately - see example 9 below)
%          Transmit         (Number) (default=1=true; either 1 (the order is immediately sent to the exchange) or 0 (order waits in TWS until user transmits it)
%          Timeout          (Number) (default=inf; maximal number of seconds to wait for an IB response to a request)
%          HedgeType        (String) (default=''; one of 'D'=delta, 'B'=beta, 'F'=Forex, 'P'=pair)
%          HedgeParam       (Number) (default=[]; relevant only for hedged orders)
%          NumberOfRows     (Number) (default=1, max=10; used to retrieve deep market data if value >= 2)
%          Override         (Number) (default=0=false; either 0 (do not override default exercise action), or 1 (override: exercise out-of-money option or lapse in-the-money option)
%          WhatIf           (Number) (default=0=false; either 0 (live order), or 1 (what-if order, returning the margin impact)
%          AlgoStrategy     (String) (default='') one of 'Adaptive','ArrivalPrice',etc. - see https://interactivebrokers.github.io/tws-api/algos.html for full list
%          AlgoParams       (cell-array) parameterName,parameterValue pairs. For example: {'maxPctVol',0.25, 'riskAversion','Aggressive'}
%          OrderRef         (String) (default='') a comment that can be attached to the order and displayed in TWS (as an Order Attribute)
%
%       Financial advisors (multi-account) order data:
%          FAProfile        (String) (default='')
%          FAGroup          (String) (default='')
%          FAMethod         (String) (default='')
%          FAPercentage     (Number) (default=0)
%
%       TWAP order data: (https://interactivebrokers.github.io/tws-api/ibalgos.html#twap)
%          StrategyType     (String) (default='Marketable'; one of 'Marketable', 'Matching Midpoint', 'Matching Same Side', or 'Matching Last')
%          StartTime        (String) (default='9:00:00 EST';  format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          EndTime          (String) (default='16:00:00 EST'; format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          AllowPastEndTime (Number) (default=1=true;  either 0 (false) or 1 (true)
%          SpeedUp          (Number) (default=0=false; either 0 (false) or 1 (true)
%          MonetaryValue    (Number) (default=0)
%
%       VWAP order data: (https://interactivebrokers.github.io/tws-api/ibalgos.html#twap)
%          MaxPctVol        (Number) (default=0.1)
%          StartTime        (String) (default='9:00:00 EST';  format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          EndTime          (String) (default='16:00:00 EST'; format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          AllowPastEndTime (Number) (default=1=true;  either 0 (false) or 1 (true)
%          NoTakeLiq        (Number) (default=0=false; either 0 (false) or 1 (true)
%          MonetaryValue    (Number) (default=0)
%
%       ArrivalPx order data: (https://interactivebrokers.github.io/tws-api/ibalgos.html#arrivalprice)
%          MaxPctVol        (Number) (default=0.1)
%          RiskAversion     (String) (default='Neutral';  one of 'Get Done', 'Aggressive', 'Neutral' or 'Passive')
%          StartTime        (String) (default='9:00:00 EST';  format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          EndTime          (String) (default='16:00:00 EST'; format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          ForceCompletion  (Number) (default=0=false; either 0 (false) or 1 (true)
%          AllowPastEndTime (Number) (default=1=true;  either 0 (false) or 1 (true)
%          MonetaryValue    (Number) (default=0)
%
%       DarkIce order data: (http://interactivebrokers.github.io/tws-api/ibalgos.html#darkice)
%          DisplaySize      (Number) (default=1)
%          StartTime        (String) (default='9:00:00 EST';  format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          EndTime          (String) (default='16:00:00 EST'; format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          AllowPastEndTime (Number) (default=1=true;  either 0 (false) or 1 (true)
%          MonetaryValue    (Number) (default=0)
%
%       PctVol order data: (http://interactivebrokers.github.io/tws-api/ibalgos.html#pctvol)
%          PctVol           (Number) (default=0.1)
%          StartTime        (String) (default='9:00:00 EST';  format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          EndTime          (String) (default='16:00:00 EST'; format: 'YYYY/MM/DD hh:mm:ss TMZ' [TMZ is optional])
%          NoTakeLiq        (Number) (default=0=false; either 0 (false) or 1 (true)
%          MonetaryValue    (Number) (default=0)
%
%       BalanceImpactRisk order data: (http://interactivebrokers.github.io/tws-api/ibalgos.html#balanceimpact)
%          MaxPctVol        (Number) (default=0.1)
%          RiskAversion     (String) (default='Neutral';  one of 'Get Done', 'Aggressive', 'Neutral' or 'Passive')
%          ForceCompletion  (Number) (default=0=false; either 0 (false) or 1 (true)
%          AllowPastEndTime (Number) (default=1=true;  either 0 (false) or 1 (true)
%
%       MinImpact order data: (http://interactivebrokers.github.io/tws-api/ibalgos.html#minimpact)
%          MaxPctVol        (Number) (default=0.1)
%
%       Automated order data:
%          LimitBasis       (String) (default=''; one of 'BID','ASK')
%          LimitDelta       (Number) (default=0); units of the security's minimum tick value
%          LimitBounds      (Array of 2 numbers) (default=[0,inf]) the dynamic limit will not change beyond these values
%          LimitRepeatEvery (Number) (default=0) [seconds]
%          LimitPause       (Number) (default=0) [seconds]
%          LimitUpdateMode  (Number) (default=0) 0=up/down, 1=only increase, -1=only decrease
%          LimitChangeTime  (String) (default= now + 10 hours; format: 'YYYYMMDD hh:mm:ss' local time)
%          LimitChangeType  (String) (default='MKT'; one of MKT,MKTCLS,LMT,LMTCLS,PEGMKT,STP,STPLMT,TRAIL,REL,VWAP,TRAILLIMIT)
%          Tick             (Number) (default=0; override the security's reported tick value)
%
%       Historical data (http://www.interactivebrokers.com/en/software/api/apiguide/java/reqhistoricaldata.htm):
%             Note limitations by the IB server: http://www.interactivebrokers.com/en/software/api/apiguide/api/historical_data_limitations.htm
%          EndDateTime      (String) (default='' (=now); format: 'YYYYMMDD hh:mm:ss TMZ' [TMZ is optional])
%          DurationValue    (Number) (default=1)
%          DurationUnits    (String) (default='D'; one of 'S','D','W','M','Y' (seconds/days/weeks/months/years))
%          BarSize          (String) (default='1 min'; one of: '1 sec/min/hour/day/week/month/year','5/15/30 secs','2/3/5/15/30 mins','3 months')
%          WhatToShow       (String) (default='Trades'; one of 'Trades','MidPoint','Bid','Ask','Bid_Ask','Historical_Volatility','Option_Implied_Volatility','Option_Volume')
%          UseRTH           (Number) (default=0=false; either 0 (all data), or 1 (only data from regular trading hours)
%          FormatDate       (Number) (default=1; either 1 ('yyyymmdd  hh:mm:dd' format) or 2 (integer number format)
%
%       Streaming data (will only work when Action='Query' or 'Realtime_Bars')
%          QuotesNumber     (Number) (default=1) Number of quotes to be received
%                               inf for continuous streaming quotes for this ticker
%                               any positive value to stream only the specified number of quotes
%                               1 to get only a single quote (i.e., non-streaming); this is the default behavior
%                               0 to stop streaming quotes for this ticker; all accumulated quotes data will be returned
%                               -1 to get all accumulated streaming quotes for this ticker without stopping the streaming
%          QuotesBufferSize (Number) (default=1) controls the number of streaming quotes stored for user retrieval in
%                               a cyclic buffer. When this number of quotes has been reached, the oldest quote
%                               will be discarded whenever a new quote arrives
%          ReconnectEvery   (Number) (default=5000) Number of quotes (total of all tickers) before automated reconnection & resubscription in TWS
%                               inf to accept streaming quotes without any automated reconnection
%                               any positive value to automatically reconnect & resubscribe to streaming quotes after so many quotes are received
%                               Note: this parameter is only relevant for streaming quotes (Action='Query'), not for realtime bars
%          GenericTickList  (String) (default='') requests additional quotes data, as described in:
%                               http://www.interactivebrokers.com/en/software/api/apiguide/tables/generic_tick_types.htm
%                               example: '100, 101, 104'
%                               Note: this parameter is only relevant for streaming quotes (Action='Query'), not for realtime bars
%
%       Scanner data (http://www.interactivebrokers.com/en/software/api/apiguide/tables/available_market_scanners.htm):
%          Type               (String) (default='SCAN'; one of 'SCAN','PARAMETERS')
%          ParametersType     (String) (default='XML'; one of 'XML','struct')
%          AbovePrice         (Number) (default=0.0)
%          AboveVolume        (Number) (default=0)
%          AverageOptionVolumeAbove (Number) (default=0)
%          BelowPrice         (Number) (default=inf)
%          CouponRateAbove    (Number) (default=0.0)
%          CouponRateBelow    (Number) (default=inf)
%          ExcludeConvertible (String) (default='')
%          Instrument         (String) (default='STK'; one of 'STK','STOCK.HK','STOCK.EU') - see https://www.interactivebrokers.com/en/software/api/apiguide/tables/instruments_and_location_codes_for_market_scanners.htm
%          LocationCode       (String) (default='STK.NASDAQ') - see https://www.interactivebrokers.com/en/software/api/apiguide/tables/instruments_and_location_codes_for_market_scanners.htm
%          MarketCapAbove     (Number) (default=0.0)
%          MarketCapBelow     (Number) (default=inf)
%          MaturityDateAbove  (String) (default='')
%          MaturityDateBelow  (String) (default='')
%          MoodyRatingAbove   (String) (default='')
%          MoodyRatingBelow   (String) (default='')
%          NumberOfRows       (Number) (default=1)
%          ScanCode           (String) (default='MOST_ACTIVE') - see https://www.interactivebrokers.com/en/software/api/apiguide/tables/available_market_scanners.htm
%          ScannerSettingPairs(String) (default='')
%          SpRatingAbove      (String) (default='')
%          SpRatingBelow      (String) (default='')
%          StockTypeFilter    (String) (default='ALL'; one of 'ALL','CORP','ADR','ETF','REIT','CEF')
%
%       Fundamental data (http://www.interactivebrokers.com/en/software/api/apiguide/java/reqfundamentaldata.htm):
%          Type               (String) (default='Ratios'; one of 'Ratios','ReportSnapshot','ReportsFinSummary','ReportRatios','ReportsFinStatements','RESC','CalendarReport')
%          ParametersType     (String) (default='XML'; one of 'XML','struct')
%
%       User callback functions:
%          CallbackFunction   (String) (default='') - generic user callback invoked for ALL IB events
%          CallbackXXX        (String) (default='') - user callback invoked for IB event XXX, where XXX is one of:
%                               AccountDownloadEnd, AccountSummary, AccountSummaryEnd, BondContractDetails,
%                               CommissionReport, ConnectionClosed,  ContractDetails, ContractDetailsEnd,
%                               CurrentTime, DeltaNeutralValidation, ExecDetails, ExecDetailsEnd, FundamentalData,
%                               HistoricalData, ManagedAccounts, MarketDataType, Message, NextValidId, 
%                               OpenOrder, OpenOrderEnd, OrderStatus, Position, PositionEnd, 
%                               TickPrice, TickSize, TickString, TickGeneric, TickEFP, 
%                               TickOptionComputation, TickSnapshotEnd, RealtimeBar, ReceiveFA, 
%                               ScannerData, ScannerDataEnd, ScannerParameters, 
%                               UpdateAccountTime, UpdateAccountValue, UpdateMktDepth, 
%                               UpdateMktDepthL2, UpdateNewsBulletin, UpdatePortfolio
%
%             see: http://www.interactivebrokers.com/php/apiguide/interoperability/activex_other/activexevents.htm
%
%             Note: All callbacks are sent two arguments: the IB object, and a structure with the event data.
%                   The eventData struct has different fields for different callbacks. 
%                   The user can differentiate the events based on the eventData.eventName field (a string).
%                   All callbacks persist across separate IBC commands until they are modified.
%                   Callbacks can be unset (removed) by setting them to '' or [].
%
% OUTPUT:
%
%   orderId = -1 if unsuccessful, otherwise the ID of the placed order, or data for 'QUERY' actions
%   ibConnectionObject = reference of Java object that interfaces with IB
%   contract = reference of Java object that holds contract info for Buy/Sell actions (see example 9 below)
%   order    = reference of Java object that holds order    info for Buy/Sell actions (see example 9 below)
%   errMsg   = error message (in case of error)
%
% Examples:
%   
%   1) Buy stock:
%
%        Matlab struct alternative:
%          >> paramsStruct = [];
%          >> paramsStruct.action     = 'BUY';
%          >> paramsStruct.symbol     = 'GOOG';
%          >> paramsStruct.quantity   = 100;
%          >> paramsStruct.limitPrice = 600;
%          >> orderId = IBC(paramsStruct);
%
%        Name/value pairs alternative:
%          >> orderId = IBC('action','BUY', 'symbol','GOOG', 'quantity',100, 'limitPrice',600);
%   
%   2) Sell stock:
%
%          >> orderId = IBC('action','SELL', 'symbol','GOOG', 'quantity',100, 'limitPrice',600);
%
%   3) Get Market data for a particular stock:
%
%          >> data = IBC('action','QUERY', 'symbol','GOOG')
%          data = 
%                 reqId: 22209874
%               reqTime: '02-Dec-2010 00:47:23'
%              dataTime: '02-Dec-2010 00:47:23'
%         dataTimestamp: 734474.032914491
%                ticker: 'GOOG'
%              bidPrice: 563.68
%              askPrice: 564.47
%                  open: 562.82
%                 close: 555.71
%                   low: 562.4
%                  high: 571.57
%             lastPrice: -1
%                volume: 36891
%                  tick: 0.01
%               bidSize: 3
%               askSize: 3
%              lastSize: 0
%
%   4) Get portfolio data:
%
%          >> data = IBC('action','PORTFOLIO_DATA')
%          data =
%          1x12 struct array with fields:
%             symbol
%             localSymbol
%             exchange
%             secType
%             currency
%             right
%             expiry
%             strike
%             position
%             marketValue
%             marketPrice
%             averageCost
%             realizedPnL
%             unrealizedPnL
%             contract
%
%          >> data(1)
%          ans = 
%                  symbol: 'AMZN'
%             localSymbol: 'AMZN'
%                exchange: 'NASDAQ'
%                 secType: 'STK'
%                currency: 'USD'
%                   right: '0'
%                  expiry: ''
%                  strike: 0
%                position: 920
%             marketValue: 171580
%             marketPrice: 186.5
%             averageCost: 169.03183335
%             realizedPnL: 7513.78
%           unrealizedPnL: 16070.71
%                contract: [1x1 struct]
%
%   5) Get historical data:
%
%          >> data = IBC('action','HISTORY_DATA', 'symbol','IBM', 'barSize','1 hour', 'useRTH',1)
%          data =
%                dateTime: {1x7 cell}
%                    open: [161.08 160.95 161.66 161.17 161.57 161.75 162.07]
%                    high: [161.35 161.65 161.70 161.60 161.98 162.09 162.34]
%                     low: [160.86 160.89 161.00 161.13 161.53 161.61 161.89]
%                   close: [160.93 161.65 161.18 161.60 161.74 162.07 162.29]
%                  volume: [5384 6332 4580 2963 4728 4465 10173]
%                   count: [2776 4387 2990 1921 2949 2981 6187]
%                     WAP: [161.07 161.25 161.35 161.31 161.79 161.92 162.14]
%                 hasGaps: [0 0 0 0 0 0 0]
%
%          >> data.dateTime
%          ans = 
%             '20110225  16:30:00'   '20110225  17:00:00'   '20110225  18:00:00'   '20110225  19:00:00'
%             '20110225  20:00:00'   '20110225  21:00:00'   '20110225  22:00:00'
%
%   6) Get account data:
%
%          >> data = IBC('action','ACCOUNT_DATA')
%          data =
%                        AccountCode: 'DU12345'
%                           currency: []
%                        accountName: 'DU12345'
%                       AccountReady: 'true'
%                        AccountType: 'INDIVIDUAL'
%                        AccruedCash: -456.4
%                    AccruedDividend: 0
%                     AvailableFunds: 261700.68
%                           Billable: 0
%                        BuyingPower: 779656.96
%                        CashBalance: -825400.37
%                 CorporateBondValue: 0
%                           Currency: 'USD'
%                            Cushion: 0.361508
%                 DayTradesRemaining: -1
%                                ...  (etc. etc.)
%
%   7) Attach a user callback function to ExecDetails events (that occur upon any order execution)
%
%          >> orderId = IBC('action','BUY', 'symbol','GOOG', 'quantity',1, 'limitPrice',600, ...
%                                'CallbackExecDetails',@IBC_CallbackExecDetails);
%
%          function IBC_CallbackExecDetails(hObject,eventData,varargin)  %#ok unused
% 
%             % Extract the basic event data components
%             contractData  = eventData.contract;
%             executionData = eventData.execution;
% 
%             % Example of extracting data from the contract object:
%             % See: http://www.interactivebrokers.com/en/software/api/apiguide/java/contract.htm
%             symbol  = char(eventData.contract.m_symbol);
%             secType = char(eventData.contract.m_secType);
%             % ... and several other contract data available - see the above webpage
% 
%             % Example of extracting data from the execution object:
%             % http://www.interactivebrokers.com/en/software/api/apiguide/java/execution.htm
%             orderId     = eventData.execution.m_orderId;
%             execId      = char(eventData.execution.m_execId);
%             time        = char(eventData.execution.m_time);
%             exchange    = char(eventData.execution.m_exchange);
%             side        = char(eventData.execution.m_side);
%             shares      = eventData.execution.m_shares;
%             price       = eventData.execution.m_price;
%             permId      = eventData.execution.m_permId;
%             liquidation = eventData.execution.m_liquidation;
%             cumQty      = eventData.execution.m_cumQty;
%             avgPrice    = eventData.execution.m_avgPrice;
%             % ... and several other contract data available - see the above webpage
% 
%             % Now do something useful with all this information...
%          end
%
%   8) Cancelling an open order (one example of the many possible actions that can be done via ibConnectionObject)
%
%          >> [orderId,ibConnectionObject] = IBC('action','BUY', ...);
%          >> ibConnectionObject.cancelOrder(orderId);
%
%      Alternatively:
%
%          >> IBC('action','CANCEL', 'orderId',orderId);
%
%   9) Holding and modifying a Buy/Sell trade order before submitting:
%
%          >> [orderId,ibConnectionObject,contract,order] = IBC('action','BUY', 'Hold',1, ...);
%          >> contract.m_secIdType = 'ISIN';
%          >> contract.m_secId = 'US0378331005';  % =Apple Inc.
%          >> order.m_clearingIntent = 'Away';
%          >> order.m_settlingFirm = 'CSBLO';
%          >> order.m_allOrNone = true;
%          >> ibConnectionObject.placeOrder(orderId, contract, order);
%
% THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
% THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT
% OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
