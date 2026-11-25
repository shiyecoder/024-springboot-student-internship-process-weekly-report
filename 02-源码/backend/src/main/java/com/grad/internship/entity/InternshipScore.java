package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 完整度计算留痕。对应表 internship_score。
 */
@Data
@TableName("internship_score")
public class InternshipScore {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生姓名 */
    private String studentName;

    /** 规则ID */
    private Long ruleId;

    /** 规则版本 */
    private String ruleVersion;

    /** 输入快照 JSON */
    private String inputJson;

    /** 明细分与解释 JSON */
    private String detailJson;

    /** 总分 */
    private BigDecimal totalScore;

    /** 等级 */
    private String grade;

    /** 可改进项 */
    private String advice;

    /** 人工调整等级 */
    private String manualGrade;

    /** 人工调整原因 */
    private String manualReason;

    /** 调整人 */
    private String manualBy;

    /** 调整时间 */
    private LocalDateTime manualTime;

    /** 计算周次 */
    private Integer calcWeek;

    /** 计算时间 */
    private LocalDateTime calcTime;

}
