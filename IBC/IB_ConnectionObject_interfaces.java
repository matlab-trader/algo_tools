/*
 * THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
 * THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT
 * OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

// Link to IB's API guide: http://www.interactivebrokers.com/php/apiUsersGuide/apiguide.htm

import com.ib.client.Contract;
import com.ib.client.ContractDetails;
import com.ib.client.EClientSocket;
import com.ib.client.EWrapper;
import com.ib.client.EWrapperMsgGenerator;
import com.ib.client.Execution;
import com.ib.client.ExecutionFilter;
import com.ib.client.Order;
import com.ib.client.OrderState;
import com.ib.client.ScannerSubscription;
import com.ib.client.UnderComp;

public class IBConnection
{
	public final static String DEFAULT_TWS_HOST = "localhost";
	public final static int    DEFAULT_TWS_PORT = 7496;
	public final static int    DEFAULT_TWS_CLIENT_ID = 1;

	// Getter functions for the connection parameters
	public String getHost()
	public int    getPort()
	public int    getClientId()

	/*********************************
	 * Active requests to IB via TWS
	 *********************************/

	// Check if connected to TWS
	public boolean isConnected()

	// Disconnect from TWS
	public void disconnectFromTWS()

	// Request the version of the TWS instance to which the API application is connected
	public int getServerVersion()

	// Request the time the API application made a connection to TWS
	public String getTwsConnectionTime()

	// Request the current server time
	public void reqCurrentTime()
	public void Systime()  // same as reqCurrentTime()

	// Request market data
	public void reqMktData(int tickerId, String m_symbol, String m_secType, String m_expiry, double m_strike, String m_right, String m_exchange, String m_currency, String m_localSymbol, String genericTickList, boolean snapshotFlag)
	public void reqMktData(int tickerId, String m_symbol, String m_secType, String m_expiry, double m_strike, String m_right, String m_exchange, String m_currency, String m_localSymbol, boolean snapshotFlag)
	public void reqMktData(int tickerId, Contract contract, String genericTickList, boolean snapshotFlag)
	public void reqMktData(int tickerId, Contract contract, boolean snapshotFlag)

	// Cancel a market data request
	public void cancelMktData(int tickerId)

	// Request market depth data
	public void reqMktDepth(int tickerId, String symbol, String secType, String expiry, double strike, String right, String exchange, String currency, String localSymbol, int numRows)
	public void reqMktDepth(int tickerId, Contract contract, int numRows)

	// Cancel a market depth request
	public void cancelMktDepth(int tickerId)

	// Request historic market data
	public void reqHistoricalData(int tickerId, String symbol, String secType, String expiry, double strike, String right, String exchange, String currency, String localSymbol, String endDateTime, String durationStr, String barSizeSetting, String whatToShow, int useRTH, int formatDate)
	public void reqHistoricalData(int tickerId, Contract contract, String endDateTime, String durationStr, String barSizeSetting, String whatToShow, int useRTH, int formatDate)
	{
		//id: The TickerId for the request. Must be a unique value. When the data is received, it will be identified by this Id. This is also used when canceling the historical data request.
		//contract: This class contains attributes used to describe the contract.
		//endDateTime: Use the format yyyymmdd hh:mm:ss tmz, where the time zone is allowed (optionally) after a space at the end.
		//durationStr: This is the time span the request will cover, and is specified using the format: <integer> <unit>, i.e., 1 D, where valid units are:   " S (seconds),   " D (days),     " W (weeks)
		//  " M (months),   " Y (years). If no unit is specified, seconds are used.  Also, note "years" is currently limited to one.
		//barSizeSetting: Specifies the size of the bars that will be returned (within IB/TWS limits). Valid values include: Bar Size: 1 sec, 5 secs, 15 secs, 30 secs, 1 min, 2 mins, 3 mins
		//  5 mins, 15 mins, 30 mins, 1 hour, 1 day, 1 week, 1 month, 3 months, 1 year
		//whatToShow: Valid values include: TRADES, MIDPOINT, BID, ASK,  BID_ASK, HISTORICAL_VOLATILITY, OPTION_IMPLIED_VOLATILITY,   OPTION_VOLUME
		//useRTH: Determines whether to return all data available during the requested time span, or only data that falls within regular trading hours. Valid values include:
		//  0 - all data is returned even where the market in question was outside of its regular trading hours.
		//  1 - only data within the regular trading hours is returned, even if the requested time span falls partially or completely outside of the RTH.
		//formatDate: Determines the date format applied to returned bars. Valid values include:
		//  1 - dates applying to bars returned in the format: yyyymmdd{space}{space}hh:mm:dd
		//  2 - dates are returned as a long integer specifying the number of seconds since 1/1/1970 GMT.
	}

	// Cancel historic data request
	public void cancelHistoricalData(int tickerId)

	// Request contract details
	public void reqContractDetails(int tickerId, Contract contract)

	// Create a contract
	public Contract createContract ()  // default contract: USD on SMART, empty fields
	public Contract createContract(String symbol, String secType, String expiry, double strike, String right, String exchange, String currency, String localSymbol)
	{
		//symbol: symbol of the underlying asset
		//secType: security type:STK,OPT,FUT,IND,FOP,CASH,BAG
		//expiry: Use the format YYYYMM.
		//strike: The strike price.
		//right: Valid values are: P, PUT, C, CALL
		//exchange: The order destination, such as Smart.
		//currency: Specifies the currency
		//localSymbol: local exchange symbol of the underlying asset
	}

	// Create an order
	public Order createOrder ()  // default order: Buy 0 LMT 0, RTH only
	public Order createOrder(String action, int quantity, String type, double lmtPrice, double auxPrice, String tif, String ocaGroup, int parentId, String goodAfterTime, String goodTillDate, double trailStopPrice, int triggerMethod, boolean outsideRTH)
	{
		//action: Identifies the side
		//quantity: the order quantity
		//type: dentifies the order type. Valid values are: MKT, MKTCLS,LMT,LMTCLS,PEGMKT,SCALE,STP,STPLMT,TRAIL,REL,VWAP,TRAILLIMIT,
		//lmtPrice: this is the LIMIT price, used for limit, stop-limit and relative orders. In all other c
		//auxPrice: this is the STOP price for stop-limit orders, and the offset amount for relative orders. In all other cases, specify zero.
		//tif: the time in force. Valid values are: DAY, GTC, IOC, GTD
		//ocaGroup: Identifies an OCA (one cancels all) group
		//parentId: the order ID of the parent order, used for bracket and auto trailing stop orders.
		//goodAfterTime: The trade's "Good After Time," format "YYYYMMDD hh:mm:ss (optional time zone)", use an empty String if not applicable.
		//goodTillDate: You must enter a tif value of GTD. The trade's "Good Till Date," format is:
		//  YYYYMMDD hh:mm:ss (optional time zone) - Use an empty String if not applicable
		//trailStopPrice: For TRAILLIMIT orders only
		//triggerMethod: Specifies how Simulated Stop, Stop-Limit and Trailing Stop orders are triggered. Valid values are:
		//  0 - The default value. The "double bid/ask" method will be used for orders for OTC stocks and US options. All other orders will used the "last" method.
		//  1 - use "double bid/ask" method, where stop orders are triggered based on two consecutive bid or ask prices.
		//  2 - "last" method, where stop orders are triggered based on the last price.
		//  3 - double last method 
		//  4 - bid/ask method 
		//  7 - last or bid/ask method 
		//  8 - mid-point method
		//outsideRth: If set to true, allows orders to also trigger or fill outside of regular trading hours
	}

	// Place an order
	public void placeOrder(int orderId, String symbol, String secType, String expiry, double strike, String right, String exchange, String currency, String localSymbol, String action, int Quantity, String Type, double lmtPrice, double auxPrice, String tif, String ocaGroup, int parentId, String goodAfterTime, String goodTillDate, double trailStopPrice, int triggerMethod, boolean outsideRTH)
	public void placeOrder(int orderId, Contract contract, Order order)

	// Cancel a placed order
	public void cancelOrder(int orderId)

	// Requests account values, portfolio, and account update time information
	public void reqAccountUpdates(boolean subscribeFlag, String acctCode)

	// Requests a list of the day's execution reports
	public void reqExecutions(int reqId, ExecutionFilter executionFilter)

	// Requests a list of current open orders for the requesting client and associates TWS open orders with the client.
	// The association only occurs if the requesting client has a Client ID of 0.
	public void reqOpenOrders()

	// Requests a list of all open orders
	public void reqAllOpenOrders()

	// Automatically associates a new TWS with the client. The association only occurs if the requesting client has a Client ID of 0
	public void reqAutoOpenOrders(boolean autoBindFlag)

	// Requests IB news bulletins
	public void reqNewsBulletins(boolean allMsgsFlag)

	// Cancels IB news bulletins
	public void cancelNewsBulletins()

	// Requests a list of Financial Advisor (FA) managed account codes
	public void reqManagedAccts()

	// Requests FA configuration information from TWS
	public void requestFA(int faDataType)

	// Modifies FA configuration information from the API
	public void replaceFA(int faDataType, String xmlStr)

	// Requests an XML document that describes the valid parameters of a scanner subscription
	public void reqScannerParameters()

	// Requests market scanner results
	public void reqScannerSubscription(int tickerId, ScannerSubscription scannerSubscription)

	// Cancels a scanner subscription
	public void cancelScannerSubscription(int tickerId)

	// Requests real-time bars
	public void reqRealTimeBars(int tickerId, Contract contract, int intVal, String str, boolean flag)

	// Cancels real-time bars
	public void cancelRealTimeBars(int tickerId)

	// Exercises options
	public void exerciseOptions(int tickerId, Contract contract, int exerciseAction, int exerciseQuantity, String account, int override)

	// Requests Reuters global fundamental data. There must be a subscription to Reuters Fundamental set up in Account Management before you can receive this data
	public void reqFundamentalData(int id, Contract contract, String str)

	// Cancels Reuters global fundamental data
	public void cancelFundamentalData(int id)

	// Request the next available reqId
	public void reqNextValidId() // same as reqId() below
	public void reqId() // a single ID
	public void reqIds(int numIds) // multiple IDs

	// Market Data requests:
	// Calculate the implied volatility of a contract
	public void calculateImpliedVolatility(int reqId, Contract contract, double optionPrice, double underPrice)

	// Cancel request to calculate the implied volatility of a contract
	public void cancelCalculateImpliedVolatility(int reqId)

	// Calculate an option price
	public void calculateOptionPrice(int reqId, Contract contract, double volatility, double underPrice)

	// Cancel request to calculate an option price
	public void cancelCalculateOptionPrice(int reqId)

	// Cancel all open API orders - 9.65
	public void reqGlobalCancel()

	// Request market data type (1 for real-time streaming market data or 2 for frozen market data) - 9.66
	public void reqMarketDataType(int marketDataType)

	// Requests reception of the data from the TWS Account Window Summary tab - 9.69
	public void reqAccountSummary(int reqId, String group, String tags)

	// Requests cancellation of request for data from the TWS Account Window Summary tab - 9.69
	public void cancelAccountSummary(int reqId)

	// Requests reception of real-time position data for an all accounts - 9.69
	public void reqPositions()

	// Requests cancellation of request for real-time position data for an all accounts - 9.69
	public void cancelPositions()

	// Sets the level of API request and processing logging
	public void setServerLogLevel(int logLevel)

	// Set the message display level (0=display all messages; 1=display errors only; 2=display no messages)
	public void setMsgDisplayLevel(int displayLevel)

	// Get the message display level
	public int getMsgDisplayLevel()

	// Set the Done flag
	public void setDone(boolean flag)

	// Get the Done flag
	public boolean isDone()

	/****************************
	 * IB Callbacks
	 ****************************/

	// Error and informational messages
	public void error(String str) 
	public void error(int data1, int data2, String str) 
	public void error(Exception e) 

	// TWS connection has closed
	public void connectionClosed()

	// Get market data
	public void tickPrice(int tickerId, int field, double price, int canAutoExecute)

	public void tickSize(int tickerId, int field, int size) 

	public void tickString(int tickerId, int field, String value) 

	public void tickGeneric(int tickerId, int field, double generic)

	public void tickEFP(int tickerId, int field, double basisPoints, String formattedBasisPoints, double totalDividends, int holdDays, String futureExpiry, double dividendImpact, double dividendsToExpiry) 

	public void tickOptionComputation(int tickerId, int field, double impliedVol, double delta, double modelPrice, double pvDividend) 
	public void tickOptionComputation(int tickerId, int field, double impliedVol, double delta, double optPrice, double pvDividend, double gamma, double vega, double theta, double undPrice)

	// Indicates end of tick messages
	public void tickSnapshotEnd(int reqId) 

	// Receives execution report information
	public void execDetails(int orderId, Contract contract, Execution execution) 

	// Indicates end of execution report messages
	public void execDetailsEnd(int reqId) 

	// Receives historical data results
	public void historicalData(int reqId, String date, double open, double high, double low, double close, int volume, int count, double WAP, boolean hasGaps) 

	// Receives the next valid order ID upon connection
	public void nextValidId(int orderId) 

	// Receive data about open orders
	public void openOrder(int orderId, Contract contract, Order order) 
	public void openOrder(int orderId, Contract contract, Order order, OrderState orderState) 

	// Indicates end of open orders messages
	public void openOrderEnd() 

	// Receive data about orders status
	public void orderStatus(int orderId, String status, int filled, int remaining, double avgFillPrice, int permId, int parentId, double lastFillPrice, int clientId) 
	public void orderStatus(int orderId, String status, int filled, int remaining, double avgFillPrice, int permId, int parentId, double lastFillPrice, int clientId, String whyHeld) 

	// Receives a list of Financial Advisor (FA) managed accounts
	public void managedAccounts(String accountsList) 

	// Receives Financial Advisor (FA) configuration information
	public void receiveFA(int faDataType, String xml)

	// Receives an XML document that describes the valid parameters of a scanner subscription
	public void scannerParameters(String xml) 

	// Receives market scanner results
	public void scannerData(int reqId, int rank, ContractDetails contractDetails, String distance, String benchmark, String projection, String legsStr) 

	// Indicates end of scanner results messages
	public void scannerDataEnd(int reqId) 

	// Receives the last time account information was updated
	public void updateAccountTime(String timeStamp) 

	// Receives current account values
	public void updateAccountValue(String key, String value, String currency) 
	public void updateAccountValue(String key, String value, String currency, String accountName) 

	// Receives IB news bulletins
	public void updateNewsBulletin(int msgId, int msgType, String message, String origExchange) 

	// Receives market depth information
	public void updateMktDepth(int tickerId, int position, int operation, int side, double price, int size) 

	// Receives Level 2 market depth information
	public void updateMktDepthL2(int tickerId, int position, String marketMaker, int operation, int side, double price, int size) 

	// Receives current portfolio information
	public void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue, double averageCost, double unrealizedPNL, double realizedPNL) 
	public void updatePortfolio(Contract contract, int position, double marketPrice, double marketValue, double averageCost, double unrealizedPNL, double realizedPNL, String accountName) 

	// Receives contract information
	public void contractDetails(int reqId, ContractDetails contractDetails) 

	// Receives bond contract information
	public void bondContractDetails(int reqId, ContractDetails contractDetails) 

	// Identifies the end of a given contract details request
	public void contractDetailsEnd(int reqId) 

	// Receives real-time bars
	public void realtimeBar(int reqId, long time, double open, double high, double low, double close, long volume, double wap, int count) 

	// Receives the current system time on the server
	public void currentTime(long time) 

	// Receives Reuters global fundamental market data
	public void fundamentalData(int reqId, String data) 

	public void accountDownloadEnd(String accountName) 

	public void deltaNeutralValidation(int reqId, UnderComp underComp) 

	// Receives market data type information - 9.66
	public void marketDataType(int reqId, int marketDataType)

	// Receives commission report information - 9.67
	public void commissionReport(CommissionReport commissionReport)

	// Receives the data from the TWS Account Window Summary tab - 9.69
	public void accountSummary(int reqId, String account, String tag, String value, String currency)

    // Indicates end of account-summary messages - 9.69
	public void accountSummaryEnd(int reqId)

	// Receives real-time position for an account - 9.69
	public void position(String account, Contract contract, int pos)

	// Indicates end of position messages - 9.69
	public void positionEnd()
}