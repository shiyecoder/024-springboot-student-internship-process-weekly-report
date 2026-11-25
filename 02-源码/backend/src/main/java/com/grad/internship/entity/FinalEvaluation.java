package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 结项评价。对应表 final_evaluation。
 */
@Data
@TableName("final_evaluation")
public class FinalEvaluation {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生姓名 */
    private String studentName;

    /** 企业评分（5分制） */
    private BigDecimal companyScore;

    /** 企业评语 */
    private String companyComment;

    /** 企业评价人 */
    private String companyEvaluator;

    /** 企业评价时间 */
    private LocalDateTime companyTime;

    /** 校内评分（百分制） */
    private Integer schoolScore;

    /** 校内评语 */
    private String schoolComment;

    /** 校内评价人 */
    private String schoolEvaluator;

    /** 校内评价时间 */
    private LocalDateTime schoolTime;

    /** 周报完成度 */
    private BigDecimal reportScore;

    /** 总评 */
    private BigDecimal totalScore;

    /** 等级 */
    private String grade;

    /** 材料是否齐全 */
    private Integer materialsOk;

    /** 状态：待评价/评价中/已结项 */
    private String status;

    /** 创建时间 */
    private LocalDateTime createTime;

}
