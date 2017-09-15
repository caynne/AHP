#第一步
CREATE DATABASE train30day;
USE train30day;
#第二步
CREATE TABLE IF NOT EXISTS user_register(
id BIGINT(20) NOT NULL AUTO_INCREMENT,
userid BIGINT(20) COMMENT "会员id",
register_channel VARCHAR(10) COMMENT "注册渠道",
src VARCHAR(10) COMMENT"注册终端",
register_ip VARCHAR(20) COMMENT "注册ip地址",
register_time VARCHAR(20) COMMENT "注册时间",
PRIMARY KEY (id)
);

#第三步
CREATE TABLE IF NOT EXISTS user_certified(
id BIGINT(20) NOT NULL AUTO_INCREMENT,
userid BIGINT(20) COMMENT "会员id",
cert_inentity INT(5) COMMENT "实名认证状态",
cert_type INT(5) COMMENT"实名认证类型",
cert_time VARCHAR(20) COMMENT "实名认证时间",
PRIMARY KEY (id)
);

#第四步
CREATE TABLE IF NOT EXISTS user_recharge_detail(
id BIGINT(20) NOT NULL AUTO_INCREMENT,
rechargeid BIGINT(20) COMMENT "充值订单ID",
userid BIGINT(20) COMMENT "会员id",
recharge_submit_time VARCHAR(20) COMMENT "充值提交时间",
recharge_submit_amount INT(10) COMMENT"充值提交金额",
recharge_status INT(5) COMMENT "充值状态0:失败,1:成功",
recharge_success_time VARCHAR(20) COMMENT "充值成功时间",
PRIMARY KEY (id)
);

#第五步
CREATE TABLE IF NOT EXISTS user_invest_detail(
id BIGINT(20) NOT NULL AUTO_INCREMENT,
investid BIGINT(20) COMMENT "投资订单ID",
userid BIGINT(20) COMMENT "会员id",
invest_time VARCHAR(20) COMMENT "投资时间",
invest_amount INT(20) COMMENT"投资金额",
invest_product VARCHAR(10) COMMENT "投资的产品",
invest_type INT(5) COMMENT "投资类型0:新手投资,1:短期投资,2:年化投资",
PRIMARY KEY (id)
);

#第六步
INSERT INTO user_register SELECT * FROM user_register$;
INSERT INTO user_certified SELECT * FROM user_certified$;
INSERT INTO user_recharge_detail SELECT * FROM user_recharge_detail$;
INSERT INTO user_invest_detail SELECT * FROM user_invest_detail$;

#第七步
#先创建一个时间监控的常量表
CREATE TABLE IF NOT EXISTS const(
monitor VARCHAR(10)
);
INSERT INTO const(monitor) VALUES('00d');
INSERT INTO const(monitor) VALUES('07d');
INSERT INTO const(monitor) VALUES('14d');
INSERT INTO const(monitor) VALUES('30d');

#将刚创建的常量表与用户注册表关联，增加“时间监控”
CREATE TEMPORARY TABLE temp_1
SELECT * FROM
(SELECT urg.`register_time` ,urg.`register_channel` ,COUNT(1) AS'register_num'
FROM user_register$ AS urg
GROUP BY urg.`register_time`,urg.`register_channel`) AS tb1 ,const;

#第八步
CREATE TABLE temp_2 AS
SELECT urg.register_time,urg.register_channel,'00d'AS monitor_time,
	COUNT(DISTINCT CASE WHEN uct.cert_inentity =1 THEN urg.userid END) AS 'certified_num'
FROM user_register AS urg
JOIN user_certified AS uct ON (urg.userid = uct.userid)
WHERE DATEDIFF(uct.cert_time,urg.register_time) = 0
GROUP BY urg.register_channel,urg.register_time,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'07d'AS monitor_time,
	COUNT(DISTINCT CASE WHEN uct.cert_inentity =1 THEN urg.userid END) AS 'certified_num'
FROM user_register AS urg
JOIN user_certified AS uct ON (urg.userid = uct.userid)
WHERE DATEDIFF(uct.cert_time,urg.register_time) <= 7
GROUP BY urg.register_channel,urg.register_time,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'14d'AS monitor_time,
	COUNT(DISTINCT CASE WHEN uct.cert_inentity =1 THEN urg.userid END) AS 'certified_num'
FROM user_register AS urg
JOIN user_certified AS uct ON (urg.userid = uct.userid)
WHERE DATEDIFF(uct.cert_time,urg.register_time) <= 14
GROUP BY urg.register_channel,urg.register_time,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'30d'AS monitor_time,
	COUNT(DISTINCT CASE WHEN uct.cert_inentity =1 THEN urg.userid END) AS 'certified_num'
FROM user_register AS urg
JOIN user_certified AS uct ON (urg.userid = uct.userid)
WHERE DATEDIFF(uct.cert_time,urg.register_time) <= 30
GROUP BY urg.register_channel,urg.register_time,monitor_time;


#第九步
DROP TABLE temp_2;
CREATE TABLE temp_3 AS
SELECT urg.register_time,urg.register_channel,'00d' AS monitor_time,
	COUNT(DISTINCT urg.userid) AS 'recharge_submit_num',
	COUNT(DISTINCT CASE WHEN urd.recharge_status = 1 THEN urd.userid END) AS 'recharge_success_num',
	SUM(CASE WHEN urd.recharge_status = 1 THEN urd.recharge_submit_amount ELSE 0 END) AS 'recharge_submit_amount'
FROM user_register AS urg
JOIN user_recharge_detail AS urd ON (urg.userid = urd.userid)

WHERE DATEDIFF(urd.recharge_submit_time,urg.register_time ) = 0
GROUP BY urg.register_time,urg.register_channel,monitor_time

UNION ALL 

SELECT urg.register_time,urg.register_channel,'07d' AS monitor_time,
	COUNT(DISTINCT urg.userid) AS 'recharge_submit_num',
	COUNT(DISTINCT CASE WHEN urd.recharge_status = 1 THEN urd.userid END) AS 'recharge_success_num',
	SUM(CASE WHEN urd.recharge_status = 1 THEN urd.recharge_submit_amount ELSE 0 END) AS 'recharge_submit_amount'
FROM user_register AS urg
JOIN user_recharge_detail AS urd ON (urg.userid = urd.userid)
WHERE DATEDIFF(urd.recharge_submit_time,urg.register_time) <= 7
GROUP BY urg.register_time,urg.register_channel,monitor_time

UNION ALL

SELECT urg.register_time,urg.register_channel,'14d' AS monitor_time,
	COUNT(DISTINCT urg.userid) AS 'recharge_submit_num',
	COUNT(DISTINCT CASE WHEN urd.recharge_status = 1 THEN urd.userid END) AS 'recharge_success_num',
	SUM(CASE WHEN urd.recharge_status = 1 THEN urd.recharge_submit_amount ELSE 0 END) AS 'recharge_submit_amount'
FROM user_register AS urg
JOIN user_recharge_detail AS urd ON (urg.userid = urd.userid)
WHERE DATEDIFF(urd.recharge_submit_time,urg.register_time) <= 14
GROUP BY urg.register_time,urg.register_channel,monitor_time

UNION ALL

SELECT urg.register_time,urg.register_channel,'30d' AS monitor_time,
	COUNT(DISTINCT urg.userid) AS 'recharge_submit_num',
	COUNT(DISTINCT CASE WHEN urd.recharge_status = 1 THEN urd.userid END) AS 'recharge_success_num',
	SUM(CASE WHEN urd.recharge_status = 1 THEN urd.recharge_submit_amount ELSE 0 END) AS 'recharge_submit_amount'
FROM user_register AS urg
JOIN user_recharge_detail AS urd ON (urg.userid = urd.userid)
WHERE DATEDIFF(urd.recharge_submit_time,urg.register_time) <= 30
GROUP BY urg.register_time,urg.register_channel,monitor_time;

#第十步
CREATE TABLE temp_4 AS
SELECT urg.register_time,urg.register_channel,'00d' AS monitor_time,
	COUNT(DISTINCT uid.userid) AS "invert_num",
	SUM(uid.invest_amount) AS 'invest_amount',
	SUM(CASE WHEN invest_type =2 THEN uid.invest_amount ELSE 0 END) AS 'annual_invest_amount'
FROM user_register AS urg
JOIN user_invest_detail AS uid ON (uid.userid = urg.userid)
WHERE DATEDIFF(uid.invest_time,urg.register_time) = 0
GROUP BY urg.register_time,urg.register_channel,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'07d' AS monitor_time,
	COUNT(DISTINCT uid.userid) AS "invert_num",
	SUM(uid.invest_amount) AS 'invest_amount',
	SUM(CASE WHEN invest_type =2 THEN uid.invest_amount ELSE 0 END) AS 'annual_invest_amount'
FROM user_register AS urg
JOIN user_invest_detail AS uid ON (uid.userid = urg.userid)
WHERE DATEDIFF(uid.invest_time,urg.register_time) <= 7
GROUP BY urg.register_time,urg.register_channel,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'14d' AS monitor_time,
	COUNT(DISTINCT uid.userid) AS "invert_num",
	SUM(uid.invest_amount) AS 'invest_amount',
	SUM(CASE WHEN invest_type =2 THEN uid.invest_amount ELSE 0 END) AS 'annual_invest_amount'
FROM user_register AS urg
JOIN user_invest_detail AS uid ON (uid.userid = urg.userid)
WHERE DATEDIFF(uid.invest_time,urg.register_time) <=14
GROUP BY urg.register_time,urg.register_channel,monitor_time
UNION ALL
SELECT urg.register_time,urg.register_channel,'30d' AS monitor_time,
	COUNT(DISTINCT uid.userid) AS "invert_num",
	SUM(uid.invest_amount) AS 'invest_amount',
	SUM(CASE WHEN invest_type =2 THEN uid.invest_amount ELSE 0 END) AS 'annual_invest_amount'
FROM user_register AS urg
JOIN user_invest_detail AS uid ON (uid.userid = urg.userid)
WHERE DATEDIFF(uid.invest_time,urg.register_time) <=30
GROUP BY urg.register_time,urg.register_channel,monitor_time;

#第十一步：
CREATE TABLE user_analysis AS 
SELECT DATE_FORMAT(t1.register_time,"%Y%m%d")AS register_time,t1.register_channel, t1.register_num,t1.monitor, t2.certified_num, t3.recharge_submit_num,t3.recharge_success_num,t3.recharge_submit_amount,
	CASE WHEN t4.invert_num IS NULL THEN 0 ELSE t4.invert_num END AS invert_num,
	CASE WHEN t4.invest_amount IS NULL THEN 0 ELSE t4.invest_amount END AS invest_amount,
	CASE WHEN t4.annual_invest_amount IS NULL THEN 0 ELSE t4.annual_invest_amount END AS annual_invest_amount
FROM temp_1 AS t1
LEFT JOIN temp_2 AS t2
ON t1.register_time = t2.register_time AND t1.register_channel = t2.register_channel AND t1.monitor = t2.monitor_time
LEFT JOIN temp_3 AS t3
ON t1.register_time = t3.register_time AND t1.register_channel = t3.register_channel AND t1.monitor = t3.monitor_time
LEFT JOIN temp_4 AS t4
ON t1.register_time = t4.register_time AND t1.register_channel = t4.register_channel AND t1.monitor = t4.monitor_time
ORDER BY DATE_FORMAT(t1.register_time,"%Y%m%d"),t1.register_channel,t1.monitor;


#第十二步：
#认证总人数
CREATE TABLE temp_5 AS 
SELECT user_register.`register_channel`,COUNT(DISTINCT user_register.`userid`) AS 'register_num'
FROM user_register
GROUP BY user_register.`register_channel`;

#首次投资

CREATE  TABLE temp_6 AS 
SELECT urg.`register_channel`,COUNT(DISTINCT urg.`userid`) AS "invest_once_clients"
FROM user_register$ AS urg
WHERE urg.`userid` IN (
SELECT user_invest_detail$.`userid`
FROM user_invest_detail$
GROUP BY user_invest_detail$.`userid`
HAVING COUNT(user_invest_detail$.`userid`)>=1)
GROUP BY urg.`register_channel`;

#二次投资人数
DROP TABLE temp_7;
CREATE  TABLE temp_7 AS
SELECT urg.`register_channel`,COUNT(DISTINCT urg.`userid`) AS "invest_multi_clients"
FROM user_register$ AS urg
WHERE urg.`userid` IN (
SELECT user_invest_detail$.`userid`
FROM user_invest_detail$
GROUP BY user_invest_detail$.`userid`
HAVING COUNT(user_invest_detail$.`userid`)>=2)
GROUP BY urg.`register_channel`;

#获客成本 
CREATE TABLE temp_8 AS
SELECT uid.`userid`,MIN(uid.`investid`) 
FROM user_invest_detail AS uid
WHERE uid.`invest_amount` >=50
GROUP BY uid.`userid`  ;


SELECT  urg.`register_channel`,
	COUNT(temp_8.`userid`) * 300 AS 'promotion_cost',
	temp_5.`register_num`,
	COUNT(DISTINCT uid.`investid`) AS 'invest_num',
	temp_6.`invest_once_clients`,
	temp_7.`invest_multi_clients`,	
	SUM(uid.`invest_amount`) AS 'invest_amount',
	SUM(CASE WHEN uid.`invest_type`=2 THEN uid.`invest_amount` ELSE 0 END) AS 'annual_invest_amount'	
FROM user_invest_detail AS uid
JOIN user_register AS urg ON (uid.`userid` = urg.`userid`)
JOIN temp_5 ON (temp_5.`register_channel` = urg.`register_channel`)
JOIN temp_6 ON (temp_6.`register_channel`=urg.`register_channel`)
JOIN temp_7 ON (temp_7.`register_channel` = urg.`register_channel`)
JOIN temp_8 ON (temp_8.`userid` = urg.`userid`)
GROUP BY urg.`register_channel`;



