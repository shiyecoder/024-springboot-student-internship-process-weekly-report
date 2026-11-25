package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 阶段里程碑。对应表 internship_milestone。
 */
@Data
@TableName("internship_milestone")
public class InternshipMilestone {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 实习档案ID */
    private Long applicationId;

    /** 序号 */
    private Integer seqNo;

    /** 里程碑名称 */
    private String title;

    /** 计划周次 */
    private Integer planWeek;

    /** 状态：未开始/进行中/已完成/已延期 */
    private String status;

    /** 完成日期 */
    private LocalDate completeDate;

    /** 延期天数 */
    private Integer delayedDays;

    /** 创建时间 */
    private LocalDateTime createTime;

}
