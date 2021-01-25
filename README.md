# Marketing-Mix-Modeling
This MMM project aims to use historical data to build a model to explore sales contribution for a fashion retail company in NYC, and predict future sales. This project also aims to using the model and predicted result to to optimize future media plan and maximize the future sales.
### Below are the steps for this project:

#### 1. Discriptive analysis on historical data (Tableau, MySQL)
1.2 MMM sales tableau.twb
#### 2. ETL (Granualarity: Weekly) (MySQL, Excel)
2.1 MMM.sql
2.2 Stack table (.csv) having original variable values with media sub-categories.
2.3 Final Media table (.xlsx): Aggragated and transformation values for media variables with media transformation process (Lag, Decay, Alpha).
2.4 Final table for modeling: All other variables with final values for media variable.

#### 3. Modeling and Prediction (R)
Model: multivariable regression
Language: R
Dependent Variable: Sales
Independent Variable: 
    Baesline: July_4th, Black_Friday, CCI, Sales.Event, 
    Media: NationalTV, PaidSearch, Wechat, Magazine, Display, Facebook, Comp.Media.Spend.
Model Evaluation: MAPE, R^2
3.1 Main script.R
3.2. contribution
3.3. Activity and Spend
3.4 AVM(actual vs model)
3.5 My Side_Model

#### 4. Media plan optimization and future sales maximazation (Excel Solver)
The optimization is completed in this file:
4.1 Optimizer_completed.xlsx

#### 5. Presentation (Tableau, Microsoft Powerpoint)

5.1(using 3.2 as data source) mmm final visualization.twb
5.2(using 3.4 as data source) mmm final avm visualization.twb
5.3.1 Side_Model
5.3.2 Side diagnostic.twb
5.4.1 2017-2018 media spend.csv
5.4.2 2017-2018 media spend.twb
5.5.1 optimizer
5.5.2 optimizer.twb
5.6 MMM final slides.pdf

