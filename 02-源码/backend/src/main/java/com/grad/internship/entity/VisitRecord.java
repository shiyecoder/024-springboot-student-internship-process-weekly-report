package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 走访记录。对应表 visit_record。
 */
@Data
@TableName("visit_record")
public class VisitRecord {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 走访编号 */
    private String visitNo;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生姓名 */
    private String studentName;

    /** 企业 */
    private String companyName;

    /** 方式：电话/现场 */
    private String visitType;

    /** 走访日期 */
    private LocalDate visitDate;

    /** 参与人 */
    private String participants;

    /** 学生表现 */
    private String studentPerformance;

    /** 企业意见 */
    private String companyOpinion;

    /** 走访照片 */
    private String photo;

    /** 教师ID */
    private Long teacherId;

    /** 教师姓名 */
    private String teacherName;

    /** 创建时间 */
    private LocalDateTime createTime;

}
