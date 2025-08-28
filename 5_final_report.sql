CREATE VIEW vendor_report AS
With Freight_Summary AS (
    Select vendornumber,
           Sum(freight) as Freight_cost 
    from vendor_payments
    group by vendornumber
),
purchaseSummary AS (
    Select p.Vendornumber,
           p.vendorname,
           p.brand,
		   p.description,
           p.purchaseprice as purchase_price,
           pp.price  as Actual_price,
           pp.volume as total_volume,
           Sum(p.quantity) As total_purchase_quantity,
           Sum(p.dollars) As total_purchasedollars
    From purchase_orders as p
    Join purchase_prices as pp
      ON pp.brand = p.brand
    Where pp.price != 0 
    Group by p.vendornumber,p.vendorname,p.brand,p.description,p.purchaseprice,pp.price,pp.volume
),
Sales_summary AS( 
    Select vendorno,
           brand,
           Total_salesdollars,
           Total_Salesprice,
           Total_sales_quantity,
           Total_Excise 
    From (
        Select vendorno,
               brand,
               SUM(salesdollars) as Total_salesdollars,
               SalesPrice as Total_Salesprice,
               Sum(salesquantity) as Total_sales_quantity,
               SUM(Excisetax) as Total_Excise
        From sales
        Group by vendorno,brand,SalesPrice
    )
    Where Total_salesdollars != 0 
)

Select Distinct 
    ps.vendornumber,
    ps.vendorname,
    ps.brand,
    ps.purchase_price,
    ps.Actual_price,
    ps.Total_volume,
    ps.total_purchase_quantity,
    ps.total_purchasedollars,
    
    -- replace NULLs with 0 for sales fields
    COALESCE(ss.Total_sales_quantity, 0) AS Total_sales_quantity,
    COALESCE(ss.Total_salesdollars, 0)   AS Total_salesdollars,
    COALESCE(ss.Total_Salesprice, 0)     AS Total_Salesprice,
    COALESCE(ss.Total_Excise, 0)         AS Total_Excise,
    COALESCE(fs.Freight_cost, 0)         AS Freight_cost,

    -- calculations using COALESCE to avoid NULLs
    (COALESCE(ss.Total_Salesprice, 0) - ps.purchase_price) * COALESCE(ss.Total_sales_quantity, 0) as Gross_profit,
    Round(
        ( (COALESCE(ss.Total_Salesprice, 0) - ps.purchase_price) * COALESCE(ss.Total_sales_quantity, 0) ) 
        / NULLIF(COALESCE(ss.Total_salesdollars, 0), 0) * 100, 2
    ) as Profit_Margin,
    ROUND(Cast(COALESCE(ss.Total_sales_quantity, 0) AS Decimal(10,2)) / NULLIF(ps.total_purchase_quantity, 0), 2) AS Stock_Turnover,
    ROUND(COALESCE(ss.Total_salesdollars, 0) / NULLIF(ps.total_purchasedollars, 0), 2) AS Sales_To_Purchase_Ratio

from purchaseSummary as ps
Left Join Sales_summary as ss
       on ps.vendornumber = ss.vendorno And ps.brand = ss.brand
Left Join Freight_Summary as fs
       on ps.vendornumber = fs.vendornumber
order by ps.total_purchasedollars DESC;
