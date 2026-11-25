package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 完整度规则。对应表 internship_rule。
 */
@Data
@TableName("internship_rule")
public class InternshipRule {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 规则名称 */
    private String ruleName;

    /** 版本 */
    private String version;

    /** 里程碑完成项权重 */
    private Integer weightMilestone;

    /** 周报连续性权重 */
    private Integer weightContinuity;

    /** 附件数量权重 */
    private Integer weightAttachment;

    /** 导师反馈权重 */
    private Integer weightFeedback;

    /** 延期任务权重 */
    private Integer weightDelay;

    /** 企业评价权重 */
    private Integer weightCompany;

    /** 良好阈值 */
    private BigDecimal thresholdGood;

    /** 合格阈值 */
    private BigDecimal thresholdMid;

    /** 是否启用 */
    private Integer enabled;

    /** 生效时间 */
    private LocalDateTime effectiveTime;

    /** 创建人 */
    private String createBy;

    /** 创建时间 */
    private LocalDateTime createTime;

}
