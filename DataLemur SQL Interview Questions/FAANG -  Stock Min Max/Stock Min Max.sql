CREATE TABLE stock_prices (
	date timestamp,
	ticker varchar(4),
	open numeric(5, 2),
	high numeric(5, 2),
	low numeric(5, 2),
	close numeric(5, 2)
);

COPY stock_prices
FROM '/Users/jiehengyu/Desktop/DataLemur SQL Interview Questions/FAANG - Stock Min Max/stock_prices.csv'
WITH (FORMAT CSV, HEADER);

SELECT * FROM stock_prices;

WITH ticker_opens
AS (
	SELECT ticker,
		   max(open) AS highest_open,
		   min(open) AS lowest_open
	FROM stock_prices
	GROUP BY ticker
)
SELECT ticker_opens.ticker,
	   high_ticker.to_char AS highest_open_month,
	   ticker_opens.highest_open,
	   low_ticker.to_char AS lowest_open_month,
	   ticker_opens.lowest_open
FROM ticker_opens
LEFT JOIN (SELECT to_char(date, 'Mon-YYYY'), ticker, 
	open FROM stock_prices) AS high_ticker
	ON ticker_opens.ticker = high_ticker.ticker
		AND ticker_opens.highest_open = high_ticker.open
LEFT JOIN (SELECT to_char(date, 'Mon-YYYY'), ticker, 
	open FROM stock_prices) AS low_ticker
	ON ticker_opens.ticker = low_ticker.ticker
		AND ticker_opens.lowest_open = low_ticker.open
ORDER BY ticker_opens.ticker;
