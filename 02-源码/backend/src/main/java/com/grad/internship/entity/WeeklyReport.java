package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 周报。对应表 weekly_report。
 */
@Data
@TableName("weekly_report")
public class WeeklyReport {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 周报编号 */
    private String reportNo;

    /** 实习档案ID */
    private Long applicationId;

    /** 实习编号 */
    private String internshipNo;

    /** 学生ID */
    private Long studentId;

    /** 学生姓名 */
    private String studentName;

    /** 周次 */
    private Integer weekNo;

    /** 周开始 */
    private LocalDate weekStart;

    /** 周结束 */
    private LocalDate weekEnd;

    /** 本周任务 */
    private String taskContent;

    /** 学习收获 */
    private String harvest;

    /** 遇到的问题 */
    private String problem;

    /** 下周计划 */
    private String nextPlan;

    /** 工作场景照片 */
    private String attachmentImage;

    /** 附件 */
    private String attachmentFile;

    /** 提交时间 */
    private LocalDateTime submitTime;

    /** 截止时间 */
    private LocalDateTime deadline;

    /** 状态：草稿/待批阅/已批阅/已退修/逾期未交 */
    private String status;

    /** 批阅评分 */
    private Integer reviewScore;

    /** 批阅评语 */
    private String reviewComment;

    /** 批阅人ID */
    private Long reviewerId;

    /** 批阅人 */
    private String reviewerName;

    /** 批阅时间 */
    private LocalDateTime reviewTime;

    /** 创建时间 */
    private LocalDateTime createTime;

}
