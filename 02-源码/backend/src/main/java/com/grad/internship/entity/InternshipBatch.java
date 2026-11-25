package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 实习批次。对应表 internship_batch。
 */
@Data
@TableName("internship_batch")
public class InternshipBatch {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 批次编号 */
    private String batchNo;

    /** 学期 */
    private String semester;

    /** 适用院系 */
    private String departments;

    /** 开始日期 */
    private LocalDate startDate;

    /** 结束日期 */
    private LocalDate endDate;

    /** 周报截止时间 */
    private String reportDeadline;

    /** 补交宽限天数 */
    private Integer graceDays;

    /** 评分构成 企业/校内/周报 */
    private String scoreWeights;

    /** 必交材料 */
    private String requiredMaterials;

    /** 最低周报份数 */
    private Integer minReports;

    /** 状态：启用/已归档 */
    private String status;

    /** 创建时间 */
    private LocalDateTime createTime;

}
