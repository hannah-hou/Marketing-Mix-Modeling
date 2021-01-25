
/*Pivot*/
CREATE TABLE select * from mmm.pivot
(
SELECT 
`Month`
,SUM(IF(Region = 'East', Sales, NULL)) AS `EastSales`
,SUM(IF(Region = 'South', Sales, NULL)) AS `SouthSales`
,SUM(IF(Region = 'West', Sales, NULL)) AS `WestSales`
,SUM(IF(Region = 'North', Sales, NULL)) AS `NorthSales`
FROM mmm.testgroupby
GROUP BY `Month`
)
;

/*Unpivot*/
CREATE TABLE mmm.unpivot
(
SELECT `Month`,'East' AS Region, EastSales AS Sales FROM mmm.pivot
UNION ALL
SELECT `Month`,'South' AS Region, SouthSales AS Sales FROM mmm.pivot
UNION ALL
SELECT `Month`,'West' AS Region, WestSales AS Sales FROM mmm.pivot
UNION ALL
SELECT `Month`,'North' AS Region, NorthSales AS Sales FROM mmm.pivot
)
;

/*1. MMM Data – Comp Media Spend 
Competitors transformed*/
CREATE TABLE mmm_comp_transformed
as
select `Week`,sum(`Competitive Media Spend`) `All Competitive Media Spend`
from mmm_comp_media_spend
group by `Week`
;

/*2. MMM Data - Events
Events transformed*/
CREATE TABLE mmm_event_transformed
as
SELECT `Week`, 
		`Sales Event`, 
        IF (`Week` IN ('2014-11-24','2015-11-30','2016-11-28','2017-11-27'),1,0) AS `Black Friday`,
        IF (`Week` IN ('2014-7-7','2015-7-6','2016-7-4','2017-7-3'),1,0) AS `July 4th`
FROM
	(select distinct m.`Week`,COALESCE(e.`Sales Event`,0) `Sales Event`
	from mmm_date_metadata m
	left join mmm_event e
	on e.`Day`=m.`Day`
	order by `Week`)a;



/*3. MMM Data - Macroeconomics
mmm_econ_transformed table*/
CREATE TABLE mmm_econ_transformed
AS
select distinct d.`Week`, e.`CCI`,e.`Unemployment Rate`
from mmm_econ e, mmm_date_metadata d
where e.`Period`=d.`Month`;

/*4. MMM Data - SQL
Sales by week*/
CREATE TABLE mmm.mmm_sales_transformed
(
SELECT
b.`Week`
,ROUND(SUM(a.Sales),2) AS Sales
FROM mmm.mmm_sales_raw a
LEFT JOIN mmm.mmm_date_metadata b
ON a.`Order Date` = b.`Day`
GROUP BY b.`Week`
)
;

/*Find out all weeks that total sales are greater than 250,000*/
SELECT *
FROM mmm_sales_transformed
WHERE Sales>250000;

#Find out all the week number that sales have increased from the week before.
SELECT a.*
FROM mmm_sales_transformed a
INNER JOIN mmm_sales_transformed b
ON a.`Week`=DATE_ADD(b.`Week`,INTERVAL 1 WEEK)
WHERE a.`Sales`>b.`Sales`;

#Find out the quarter of each year that has the highest sales. 
#create table first
CREATE TABLE `QuaterlySales`
AS
SELECT YEAR(`Week`) AS `YEAR`,
		CONCAT('Q',QUARTER(`Week`)) AS `Quarter`,
        SUM(`Sales`) AS `QuaterlySales`
FROM mmm_sales_transformed
GROUP BY YEAR(`Week`),CONCAT('Q',QUARTER(`Week`));

#now select the result we want
SELECT q.*
FROM `QuaterlySales` q,
	(SELECT `YEAR`,
			MAX(`QuaterlySales`) AS `MaxSales`
	FROM `QuaterlySales`
	GROUP BY `YEAR`) a
WHERE q.`Year`=a.`Year`
	AND q.`QuaterlySales`=a.`MaxSales`;


/* MMM TV*/
SELECT * FROM mmm_offline_tv_magazine;
SELECT * FROM mmm_dma_hh;

CREATE TABLE mmm_offline_transformed
AS
SELECT `DATE`, 
	ROUND(SUM((`TV GRP`/100 * `Total HH`))/SUM(`TOTAL HH`)*100,0) AS `National TV GRP`,
    ROUND(SUM((`Magazine GRP`/100 * `Total HH`))/SUM(`TOTAL HH`)*100,0) AS `Magazine GRP`
from mmm_offline_tv_magazine a
LEFT JOIN mmm_dma_hh b
ON a.`DMA`=b.`DMA Name`
GROUP BY `DATE`;

# transform table for dcmdisplay
CREATE TABLE mmm_dcmdisplay_transformed AS
SELECT `Date`,
		SUM(CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER)) AS `Display Impression`,
        SUM(IF(`Campaign Name` LIKE '%Always_On%',CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Always On Impressions`,
        SUM(IF(`Campaign Name` LIKE '%Website%',CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Website Impressions`,
        SUM(IF(`Campaign Name` IN ('Branding Campaign','New Product Launch'),CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Branding Impressions`,
        SUM(IF(`Campaign Name` IN ('Holiday','July 4th'),CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Holiday Impressions`
FROM mmm_dcmdisplay_2015
GROUP BY `Date`;

CREATE TEMPORARY TABLE dcm_temp AS
SELECT `Date`,
		SUM(CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER)) AS `Display Impression`,
        SUM(IF(`Campaign Name` LIKE '%Always_On%',CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Always On Impressions`,
        SUM(IF(`Campaign Name` LIKE '%Website%',CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Website Impressions`,
        SUM(IF(`Campaign Name` IN ('Branding Campaign','New Product Launch'),CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Branding Impressions`,
        SUM(IF(`Campaign Name` IN ('Holiday','July 4th'),CONVERT(REPLACE(`Served Impressions`,',',''), SIGNED INTEGER),0)) AS `Display Holiday Impressions`
FROM mmm_dcmdisplay_2017
GROUP BY `Date`;
mmm_dcmdisplay_transformed

# UPSERT dcmdisplay2015&2017
#Check the overlap data and delete them.
SELECT DISTINCT a.`DATE`
FROM mmm_dcmdisplay_transformed a
INNER JOIN dcm_temp b
ON a.`DATE`=b.`DATE`;

DELETE a.*
FROM mmm_dcmdisplay_transformed a
INNER JOIN dcm_temp b
ON a.`DATE`=b.`DATE`;

#Insert new data
INSERT INTO mmm_dcmdisplay_transformed
SELECT * FROM dcm_temp;



/*<Paid Search>
(1.Create extract table */
CREATE TABLE search_extract as
select * from mmm_adwordssearch_2015;

/* (2.Delete overlap data */
DELETE a.*
FROM search_extract a
INNER JOIN mmm.mmm_adwordssearch_2017 b
ON a.`date_id` = b.`date_id`
;

/* (3.Insert new data */
INSERT INTO search_extract
SELECT * FROM mmm_adwordssearch_2017
;

/*Create a transform table ‘search_transformed’ to have
SearchImpressions & SearchClicks variables by week*/
CREATE TABLE search_transformed as
	select `date_id` `Week`,
			sum(`impressions`) SearchImpressions,
			sum(`clicks`) SearchClicks
	from search_extract
	group by `date_id`

/*
Create a new transform table ‘search_campaign_transformed’
to have SearchClicks variables with campaign name by week.
SearchAlwaysOnClick
SearchWebsiteClick (Landing Page + Retargeting)
SearchBrandingClick
*/;

CREATE TABLE search_campaign_transformed as
	SELECT `date_id` `Week`,
			SUM(`impressions`) SearchImpressions,
			SUM(`clicks`) SearchClicks,
			SUM(IF(campaign_name IN ('Always-on','Mobile Always-On'), clicks, 0)) AS `SearchAlwaysOnClick`,
			SUM(IF(campaign_name IN ('Landing Page','Retargeting'), clicks, 0)) AS `SearchWebsiteClick`,
			SUM(IF(campaign_name IN ('Branding Campaign','New Product Launch'), clicks, 0)) AS `SearchBrandingClick`
	FROM search_extract
	GROUP BY `date_id`;

/* 
<FACEBOOK>
*/

CREATE TABLE facebook_extracted as
SELECT * FROM mmm_facebook;

/*CREATE facebook_transformed TABLE */
CREATE TABLE facebook_transformed
AS (
	SELECT `Period` 'Week',
			sum(CONVERT(`ap_total_imps`,DOUBLE)) FacebookImpressions,
			sum(CONVERT(`ap_total_clicks`,DOUBLE)) FacebookClicks,
			ROUND(IF(sum(`ap_total_imps`)=0,0,
				sum(CONVERT(`ap_total_clicks`,DOUBLE))/sum(CONVERT(`ap_total_imps`,DOUBLE))
                ),3) FacebookCTR
	FROM facebook_extracted
	GROUP BY `Period`
    );

/*
create new transform table:‘fb_campaign_transformed’
to have FBImpressions variables with campaign name by week.
FBBrandingImpression
FBHolidayImpression
FBOtherImpression (combine other campaigns into this category)
*/


CREATE TABLE fb_campaign_transformed
AS (
	SELECT `Period` `Week`,
			SUM(IF(`campaign objective` = 'Branding Campaign', ap_total_imps, 0)) AS `FBBrandingImpression`,
			SUM(IF(`campaign objective` = 'Holiday', ap_total_imps, 0)) AS `FBHolidayImpression`,
			SUM(IF(`campaign objective` IN( 'Pride','July 4th','New Product Launch','Others'), ap_total_imps, 0)) AS `FBOtherImpression`
	FROM facebook_extracted
	GROUP BY `Period`
    );



/* <WECHAT> */
CREATE TABLE wechat_extracted AS
SELECT * FROM mmm_wechat;

/*CREATE wechat_transformed TABLE */
CREATE TABLE wechat_transformed AS
SELECT `Period` `Week`,
	SUM(`Article Total Read`) AS `Wechat`,
	SUM(`Article Total Read` + `Account Total Read` + `Moments Total Read`) AS WechatTotalRead,
    SUM(IF(`Campaign`='New Product Launch',`Article Total Read` + `Account Total Read` + `Moments Total Read`,0))
		AS WechatNewLaunchRead
FROM wechat_extracted
GROUP BY `Period`;

/* <STACK> */

CREATE VIEW stack
as
(;

SELECT * from 
	facebook_transformed a,
    mmm_econ_transformed b,
	fb_campaign_transformed c,
	mmm_comp_transformed d,
	mmm_event_transformed e,
	mmm_sales_transformed f,
	search_campaign_transformed g,
	search_transformed h,
	wechat_transformed i,
    mmm_dcmdisplay_transformed j,
    mmm_offline_transformed k
WHERE a.week=b.week
	AND b.week=c.week
    AND c.week=d.week
    AND d.week=e.week
    AND e.week=f.week
    AND f.week=g.week
    AND g.week=h.week
    AND h.week=i.week
    AND i.week=j.Date
    AND j.Date=k.Date
    
select * from mmm_event_transformed
