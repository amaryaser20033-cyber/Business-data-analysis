select * from Sales_All;

with Saless as (
    select 
        round(sum(orderquantity * productprice), 2) as Total_sales,
        round(sum(orderquantity * productcost), 2) as Total_cost,
        round(sum(orderquantity * (productprice - productcost)), 2) as Total_profit,
        round((sum(orderquantity * (productprice - productcost)) / sum(orderquantity * productprice)) * 100, 2) as Profit_margin,
        sum(orderquantity) as Total_Orders,
		sum(case when year(cast(OrderDate as date)) = 2015 then OrderQuantity * ProductPrice end) as Revenue2015,
        sum(case when year(cast(OrderDate as date)) = 2017 then OrderQuantity * ProductPrice end) as Revenue2017
    from Sales_All s
    join cproducts p on s.productkey = p.productkey
),
Returnss as (
    select 
        round(sum(ReturnQuantity * ProductPrice), 2) as Returns_amount
    from returns r
    join CProducts p on r.ProductKey = p.ProductKey
)
select 
    Total_orders,
    Total_sales,
    Total_cost,
    Total_profit,
    Profit_margin,
    Returns_amount,
    round(Returns_amount * 100.0 / Total_sales, 2) as Return_rate,
    round(Total_sales - Returns_amount, 2) as Revenue_after_returns,
    round(((Revenue2017 - Revenue2015) / Revenue2015) * 100, 2) as Growth_Rate
from Saless, Returnss;

--Sales by time
select 
    Year,
    Month,
    Total_sales,
    lag(total_sales) over (order by year, month) as Prev_month,
    total_sales - lag(total_sales) over (order by year, month) as Growth,
    round(
        (total_sales - lag(total_sales) over (order by year, month)) * 100.0 
        / nullif(lag(total_sales) over (order by year, month), 0), 2
    ) as Growth_rate
from (
    select 
        year(s.orderdate) as Year,
        month(s.orderdate) as Month,
        round(sum(s.orderquantity * p.productprice), 2) as Total_sales
    from sales_all s
    join cproducts p 
        on s.productkey = p.productkey
    group by year(s.orderdate), month(s.orderdate)
) as monthly_sales
order by Year, Month;

--Sales by Category
select 
    CategoryName,
    sum(OrderQuantity) as total_units_sold,
    sum(OrderQuantity * ProductPrice) as total_sales
from Sales_All s
join Products p on s.ProductKey = p.ProductKey
join Subcategories ps on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
join Categories pc on ps.ProductCategoryKey = pc.ProductCategoryKey
group by CategoryName
order by total_sales desc;

-- Sales by Territories
select 
    Country,
    Region,
    round(sum(OrderQuantity * ProductPrice),2) as total_sales
from Sales_All s
join Territories t on s.TerritoryKey = t.SalesTerritoryKey
join CProducts p on s.ProductKey = p.ProductKey
group by Country, Region
order by total_sales desc;

-- Returns by Territories
select 
    Continent,
    Country,
    round(sum(ReturnQuantity * ProductPrice),2) as Return_Amount
from Returns r
join Territories t on r.TerritoryKey = t.SalesTerritoryKey
join Products p on r.ProductKey = p.ProductKey
group by Continent, Country
order by Return_Amount desc;

--Returns by Category
select 
    c.CategoryName,
    sum(r.ReturnQuantity) as Total_Returns,
    sum(r.ReturnQuantity * p.ProductPrice) as Return_Amount
from Returns r
join CProducts p 
    on r.ProductKey = p.ProductKey
join Subcategories sc 
    on p.ProductSubcategoryKey = sc.ProductSubcategoryKey
join Categories c 
    on sc.ProductCategoryKey = c.ProductCategoryKey
group by c.CategoryName
order by Return_Amount desc;

-- Sales vs Returns  
with Saless as (
    select 
        p.ProductKey,
        ProductName,
        sum(OrderQuantity) as Total_Sold,
        sum(OrderQuantity * ProductPrice) as Total_Sales_Amount
    from Sales_All s
    join CProducts p
        on s.ProductKey = p.ProductKey
    group by p.ProductKey, ProductName, ProductPrice
),
Returnss as (
    select 
        p.ProductKey,
        ProductName,
        sum(ReturnQuantity) as Total_Returns,
        sum(ReturnQuantity * ProductPrice) as Total_Returns_Amount
    from Returns r
    join CProducts p
        on r.ProductKey = p.ProductKey
    group by p.ProductKey, ProductName, ProductPrice
)
select top 5
    s.ProductName,
    sum(Total_Sold) as Total_Sold,
    sum(Total_Returns) as Total_Returns,
    round(sum(Total_Sales_Amount),2) as Total_Sales_Amount,
    sum(Total_Returns_Amount) as Total_Returns_Amount,
    round(
        cast(sum(Total_Returns_Amount) as float) * 100 / nullif(sum(Total_Sales_Amount),0)
    ,2) as Return_Amount_Rate
from Saless s
left join Returnss r
    on s.ProductKey = r.ProductKey
group by s.ProductName
order by Total_Returns desc;

--Top products Revenue
select 
    ProductName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales
	from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	group by ProductName
    order by Total_Sales desc;

--Price Category
select 
    case 
        when productprice < 100 then 'low (<$100)'
        when productprice between 100 and 1000 then 'medium ($100-$1000)'
        else 'high (>$1000)'
    end as price_category,
    count(distinct p.productkey) as product_count,
    sum(orderquantity) as units_sold,
    round(sum(orderquantity * productprice), 2) as total_revenue
from cproducts p
join sales_all s 
    on p.productkey = s.productkey
group by 
    case 
        when productprice < 100 then 'low (<$100)'
        when productprice between 100 and 1000 then 'medium ($100-$1000)'
        else 'high (>$1000)'
    end
order by total_revenue desc;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

select *from CProducts;

into CProducts
from Products;

update CProducts
set ProductSKU = case 
       when charindex('-', ProductSKU, charindex('-', ProductSKU) + 1) > 0
       then left(ProductSKU, len(ProductSKU) - charindex('-', reverse(ProductSKU)))
       else ProductSKU
    end,
    ProductColor = case 
        when ProductColor in ('NA','Multi') then 'Unknown'
        else ProductColor
	end,
	ProductSize = case 
        when ProductSize = '0' then 'Unknown'
        else ProductSize
	end,
	ProductStyle = case 
        when ProductStyle = '0' then 'Unknown'
        else ProductStyle
	end,
	 ProductPrice = round(ProductPrice, 2),
    ProductCost  = round(ProductCost, 2),

    ProductName = case 
        when right(rtrim(CleanedColors),1) = '-' 
        then left(rtrim(CleanedColors), len(rtrim(CleanedColors)) - 1)
        else rtrim(CleanedColors) 
    end 
from CProducts c
join(
    select 
	ProductKey,
        replace(replace(replace(replace(replace(
            left(ProductName,
                case 
                    when charindex(',', ProductName) > 0 
                    then charindex(',', ProductName) - 1
                    else len(ProductName)
                end),
        'Yellow',''),'Blue',''),'Black',''),'Silver',''),'Red','') as CleanedColors
    from CProducts
) as s
on c.ProductKey = s.ProductKey;
 
select 
    ProductKey, 
	count(*) as DuplicateCount
	from CProducts
    group by ProductKey
    having count(*) > 1;

--Products Variants
select 
    count (*) as product_count,
    ProductName 
	from CProducts
	group by ProductName
	order by product_count;

select 
    count (distinct ModelName) as Total_Products,
    count (distinct p.ProductKey) as Total_Units,
	sum(OrderQuantity) as Total_units_sold,
	count(distinct OrderNumber) as Total_orders
from CProducts p
left join Sales_All s on p.ProductKey = s.ProductKey

select sum(ReturnQuantity) as Return_Quantity
from Returns

--Products Sales
select 
    count(distinct ModelName) as Total_Products,
    count(distinct case when s.ProductKey is not null then ModelName end) as Sold_Products,
    count(distinct ModelName) - 
    count(distinct case when s.ProductKey is not null then ModelName end) as Not_Sold_Products
from CProducts p
left join Sales_All s
on p.ProductKey = s.ProductKey;

--Units Sales
select 
    count(distinct p.ProductKey) as Total_Units,
    count(distinct s.ProductKey) as Sold_Units,
    count(distinct p.ProductKey) - count(distinct s.ProductKey) as Not_Sold_Units
from CProducts p
left join Sales_All s
    on p.ProductKey = s.ProductKey;

--Not Sold Products
select 
    ProductName
from CProducts p
left join Sales_All s
    on p.ProductKey = s.ProductKey
where s.ProductKey is null
	group by ProductName


--Not sold Units
select distinct 
    p.ProductKey,
    ProductName,
	ProductColor,
	ProductSize
from CProducts p
left join Sales_All s
    on p.ProductKey = s.ProductKey
where s.ProductKey is null;


--Orders By Time
select 
        year(OrderDate) as Year,
        month(OrderDate) as Month,
        sum(OrderQuantity) as Total_Orders
    from Sales_All s
    join CProducts p 
        on s.ProductKey = p.ProductKey
    group by year(OrderDate), month(OrderDate)
order by Year, Month;

--Top Subcategories
select top 5
    SubcategoryName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales
	from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	join Subcategories ps on p.ProductSubcategoryKey = ps.ProductSubcategoryKey
	group by SubcategoryName
    order by Total_Quantity desc

--Most sold products
select top 5
    ProductName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales,
    round(sum((ProductPrice - ProductCost) * OrderQuantity),2) as Total_profit
	from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	group by ProductName
    order by Total_Quantity desc;

--Bottom Sold Products 
select top 5
    ProductName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales
	from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	group by ProductName
    order by Total_Quantity asc

--Top Products Sales
select top 5
    ProductName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales,
	round(sum(ProductCost * OrderQuantity),2) as Total_Costs,
    round(sum((ProductPrice - ProductCost) * OrderQuantity),2) as Total_profit
    from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	group by ProductName
    order by Total_Sales desc

--BottOm Products Sales
select top 5
    ProductName,
	sum(OrderQuantity) as Total_Quantity,
	round(sum(ProductPrice * OrderQuantity),2) as Total_Sales
	from CProducts p
	join Sales_All s
	on p.ProductKey = s.ProductKey
	group by ProductName
    order by Total_Sales asc

--Top Products Profit 
select top 5
    ModelName,
    round(sum((p.ProductPrice - p.ProductCost) * s.OrderQuantity),2) as Total_Profit,
	round(sum((p.ProductPrice - p.ProductCost) * s.OrderQuantity) * 100.0 /
    nullif(sum(s.OrderQuantity * p.ProductPrice),0),2) as Profit_margin
from CProducts p
join Sales_All s
    on p.ProductKey = s.ProductKey
group by ModelName
order by Total_Profit desc

--Color Performance
select 
    ProductColor,
    count(distinct p.ProductKey) as Num_Products,
    coalesce(sum(OrderQuantity), 0) as Total_Units_Sold
from CProducts p
left join Sales_All s
    on p.ProductKey = s.ProductKey
	where ProductColor <> 'Unknown'
group by ProductColor
order by Total_Units_Sold desc;

--Style Performance
select 
    ProductStyle,
    count(distinct p.ProductKey) as Num_Products,
    coalesce(sum(s.OrderQuantity), 0) as Total_Units_Sold
from CProducts p
left join Sales_All s on p.ProductKey = s.ProductKey
where p.ProductStyle <> 'Unknown'
group by p.ProductStyle
order by Total_Units_Sold desc;

--Most Returns
select top 5
    s.ProductName,
    Total_Sold,
    isnull(Total_Returns,0) as Total_Returns,
    round(
        cast(isnull(r.Total_Returns,0) as float) * 100 /
        nullif(s.Total_Sold,0)
    ,2) as Return_Rate
from
(
    select 
        ProductName,
        sum(s.OrderQuantity) as Total_Sold
    from Sales_All s
    join CProducts p
        on s.ProductKey = p.ProductKey
    group by p.ProductName
) s
left join
(
    select 
        ProductName,
        sum(r.ReturnQuantity) as Total_Returns
    from Returns r
    join CProducts p
        on r.ProductKey = p.ProductKey
    group by p.ProductName
) r
on s.ProductName = r.ProductName
order by Total_Returns desc;

------------------------------------------------------------------------------
------------------------------------------------------------------------------

select * from Customers

--Total Customers
select 
    count(*) as Total_Customers,
    count(case when Gender = 'M' then 1 end) as Men,
    count(case when Gender = 'F' then 1 end) as Women
from Customers;

--Total Active Customers
select 
    count(distinct c.customerkey) as Act_Customers,
    count(distinct case when c.Gender = 'M' then c.CustomerKey end) as Men,
    count(distinct case when c.Gender = 'F' then c.CustomerKey end) as Women
from Customers as c
 join Sales_All as s 
on c.CustomerKey = s.CustomerKey;
 
 --New Customers
select 
    count(*) as New_Customers
from (
    select 
        CustomerKey,
        min(OrderDate) as First_Order_Date
    from Sales_All
    group by CustomerKey
) as first_purchase
where First_Order_Date >= '2017-01-01';

--Repeat Customers
select 
    count(*) as Repeat_Customers,
    count(*) * 1.0 / (select count(distinct CustomerKey) from Sales_All) as Repeat_Rate
from (
    select 
        CustomerKey
    from Sales_All
    group by CustomerKey
    having count(distinct OrderNumber) > 1
) t;

--Top Customers
select top 5
    c.CustomerKey,
    FirstName + ' ' + LastName as Name,
    sum(OrderQuantity) as Total_Orders,
    round(sum(OrderQuantity * ProductPrice),2) as Total_Amount
from Sales_All s
inner join Customers c on s.CustomerKey = c.CustomerKey
inner join Products p on s.ProductKey = p.ProductKey
group by c.CustomerKey, c.FirstName, c.LastName
order by Total_Orders desc;

--Age Group 
select 
    Age_Category, 
    count(*) as Total_Customers,
	round(
    cast(count(*) as float) * 100 
    / sum(count(*)) over(), 2) as Percentage
from (
    select 
        case 
            when (year(getdate()) - year(BirthDate)) < 50 then 'Under 50'
            when (year(getdate()) - year(BirthDate)) between 50 and 60 then 'Between 50 and 60'
            else 'Over 60'
        end as Age_Category
    from Customers
    where CustomerKey in (select distinct CustomerKey from Sales_All)
) as Subquery
group by Age_Category
order by Total_Customers;

--Income Category
select 
    Income_Category,
    count(*) as Total_Customers,
	round(
    cast(count(*) as float) * 100 
    / sum(count(*)) over(), 2) as Percentage
from (
    select 
        case 
            when AnnualIncome < 50000 then 'Under 50k'
            when AnnualIncome between 50000 and 90000 then 'Between 50k and 90k'
            else 'Over 90k'
        end as Income_Category
    from Customers
	where CustomerKey in (select distinct CustomerKey from Sales_All)
) as subquery
group by Income_Category
order by Total_Customers;

--Home Owner
select 
	case 
        when HomeOwner = '1' then 'Home Owner'
        else 'Renter'
		end as Home_Owner_Status,
    count(*) as Total_Customer,
	round(
	cast(count(*) as float) * 100 
    / sum(count(*)) over(), 2) as Percentage
	from Customers
	where CustomerKey in (select distinct CustomerKey from Sales_All)
	group by HomeOwner;

--Occupation distribution
select 
    Occupation,
    count(*) as Total_Customers,
	round(
    cast(count(*) as float) * 100 
    / sum(count(*)) over(), 2) as Percentage
	from Customers
	where CustomerKey in (select distinct CustomerKey from Sales_All)
	group by Occupation
	order by Total_Customers desc;

--Country distribution
select 
    Country, 
    count(distinct CustomerKey) as Total_Customers,
    round(
    cast(count(distinct CustomerKey) as float) * 100 
    / sum(count(distinct CustomerKey)) over(), 2) as Percentage 
	from Sales_All s
left join Territories t on s.TerritoryKey = t.SalesTerritoryKey
group by Country
order by Total_Customers desc;

--Customers Growth
with Firist_Date as (
    select 
        CustomerKey,
        format(min(OrderDate), 'yyyy-MM') as Month
    from Sales_All
    group by CustomerKey
),
Monthly as (
    select 
        Month,
        count(*) as New_Customers
    from Firist_Date
    group by Month
)
select 
    Month,
    New_Customers,
    lag(New_Customers) over (order by Month) as Prev_Month,
    round(
    (cast(New_Customers - lag(New_Customers) over (order by Month) as float)) 
    * 100.0
    / nullif(lag(New_Customers) over (order by Month), 0),
    2
) as Growth_Percentage
from Monthly
order by Month;