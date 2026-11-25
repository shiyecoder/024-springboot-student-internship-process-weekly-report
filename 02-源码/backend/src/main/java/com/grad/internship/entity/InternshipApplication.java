package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 实习档案主表。对应表 internship_application。
 */
@Data
@TableName("internship_application")
public class InternshipApplication {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 实习编号，业务唯一 */
    private String internshipNo;

    /** 学生ID */
    private Long studentId;

    /** 学生姓名 */
    private String studentName;

    /** 学号 */
    private String studentNo;

    /** 专业 */
    private String major;

    /** 年级 */
    private String grade;

    /** 企业ID */
    private Long companyId;

    /** 企业名称 */
    private String companyName;

    /** 岗位 */
    private String position;

    /** 行业 */
    private String industry;

    /** 城市 */
    private String city;

    /** 校内导师ID */
    private Long teacherId;

    /** 校内导师 */
    private String teacherName;

    /** 企业导师ID */
    private Long mentorId;

    /** 企业导师 */
    private String mentorName;

    /** 批次ID */
    private Long batchId;

    /** 批次编号 */
    private String batchNo;

    /** 开始日期 */
    private LocalDate startDate;

    /** 结束日期 */
    private LocalDate endDate;

    /** 来源：集中实习/自主实习 */
    private String source;

    /** 当前阶段 */
    private String stage;

    /** 周报状态 */
    private String reportStatus;

    /** 三方协议附件 */
    private String agreementFile;

    /** 保险附件 */
    private String insuranceFile;

    /** 企业接收函 */
    private String acceptFile;

    /** 最近一次流转原因 */
    private String transitionReason;

    /** 乐观锁版本号 */
    private Integer version;

    /** 逻辑删除 */
    private Integer deleted;

    /** 创建人 */
    private Long createBy;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;

}
