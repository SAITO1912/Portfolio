--商品別の売上ランキング（ABC分析）


WITH product_sales AS (
--商品ごとの売上合計の計算
  SELECT
    product_id,
    ROUND(SUM(sale_price)) AS product_total_revenue,
    COUNT(id) AS sales_count
  FROM
    `bigquery-public-data.thelook_ecommerce.order_items`
  --「キャンセル」「返品」を外す
  WHERE
    status NOT IN ('Cancelled', 'Returned')
  --商品idごとにグループ化
  GROUP BY
    product_id
),

cumulative_sales AS (
--売上が高い順に並べ、売上の累積金額と全体に対する%を計算 
  SELECT
    product_id,
    product_total_revenue,
    sales_count,
  --売上を上から順番に足していく（累積売上）
    SUM(product_total_revenue) OVER(ORDER BY product_total_revenue DESC) AS cumulative_revenue,
  --全体の総売上を計算
    SUM(product_total_revenue) OVER() AS total_revenue
  FROM
    product_sales
)

  --累積売上の比率を計算し、A, B, Cの3グループに分類
  SELECT
    product_id,
    product_total_revenue,
    sales_count,
  --全体売上に対するこの商品までの累積比率（%）
    ROUND((cumulative_revenue / total_revenue) * 100, 1) AS cumulative_percentage,
  --比率によってランク分け（70%までがA、90%までがB、それ以外はC）
  CASE
    WHEN (cumulative_revenue / total_revenue) <=0.70 THEN 'A (主力商品)'
    WHEN (cumulative_revenue / total_revenue) <=0.90 THEN 'B (準主力商品)'
    ELSE 'C (売上小)'
  END AS abc_rank
FROM
  cumulative_sales
ORDER BY
  product_total_revenue DESC;
