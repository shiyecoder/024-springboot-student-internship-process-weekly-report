package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 实习变更。对应表 internship_change。
 */
@Data
@TableName("internship_change")
public class InternshipChange {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 变更编号 */
    private String changeNo;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生姓名 */
    private String studentName;

    /** 变更类型 */
    private String changeType;

    /** 变更前 */
    private String beforeValue;

    /** 变更后 */
    private String afterValue;

    /** 变更原因 */
    private String reason;

    /** 附件 */
    private String attachment;

    /** 当前节点 */
    private String currentNode;

    /** 状态 */
    private String status;

    /** 申请时间 */
    private LocalDateTime applyTime;

    /** 校内意见 */
    private String teacherOpinion;

    /** 管理员意见 */
    private String adminOpinion;

    /** 生效时间 */
    private LocalDateTime effectiveTime;

    /** 创建时间 */
    private LocalDateTime createTime;

}
