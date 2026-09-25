--① 月別売上・注文数・客単価の推移（売上集計分析）

SELECT
--注文年月
  FORMAT_TIMESTAMP('%Y-%m',created_at) AS order_month,
--1ヶ月の総売上金額(小数点以下は四捨五入)
  ROUND(SUM(sale_price)) AS total_revenue,
--1ヶ月のユニークな注文数
  COUNT(DISTINCT order_id) AS totale_orders,
--1ヶ月の客単価(総売上÷注文数)
  ROUND(SUM(sale_price) / COUNT(DISTINCT order_id)) AS average_order_value
FROM
  `bigquery-public-data.thelook_ecommerce.order_items`
--「キャンセル」「返品」以外を集計
WHERE
  status NOT IN ('Cancelled', 'Returned')
--年月ごとに纏める(グループ化)
GROUP BY
  order_month
--古い月から順に並べる
ORDER BY
  order_month ASC;
