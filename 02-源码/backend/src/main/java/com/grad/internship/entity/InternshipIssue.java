package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 异常关怀。对应表 internship_issue。
 */
@Data
@TableName("internship_issue")
public class InternshipIssue {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 异常编号 */
    private String issueNo;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生姓名 */
    private String studentName;

    /** 企业 */
    private String companyName;

    /** 类型：岗位不符/安全问题/薪资争议/无法联系 */
    private String issueType;

    /** 等级：高/中/低 */
    private String level;

    /** 内容 */
    private String content;

    /** 上报时间 */
    private LocalDateTime reportTime;

    /** 处理人 */
    private String handlerName;

    /** 状态：待处置/处置中/已关闭 */
    private String status;

    /** 处置记录 */
    private String handleRecord;

    /** 关闭时间 */
    private LocalDateTime closeTime;

    /** 创建时间 */
    private LocalDateTime createTime;

}
