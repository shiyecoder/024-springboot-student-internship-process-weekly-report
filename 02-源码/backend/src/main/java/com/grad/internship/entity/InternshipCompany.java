package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 企业库。对应表 internship_company。
 */
@Data
@TableName("internship_company")
public class InternshipCompany {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 企业编号 */
    private String companyNo;

    /** 企业名称 */
    private String companyName;

    /** 行业 */
    private String industry;

    /** 地址 */
    private String address;

    /** 城市 */
    private String city;

    /** 联系人 */
    private String contact;

    /** 电话 */
    private String phone;

    /** 规模 */
    private String scale;

    /** 往年接收人数 */
    private Integer pastStudents;

    /** 学生评价均分 */
    private BigDecimal avgScore;

    /** 风险状态：正常/关注/风险 */
    private String riskStatus;

    /** 企业资质/办公环境图片相对路径 */
    private String licenseImage;

    /** 简介 */
    private String intro;

    /** 创建时间 */
    private LocalDateTime createTime;

}
