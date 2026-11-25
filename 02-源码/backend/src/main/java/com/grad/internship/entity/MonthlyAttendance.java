package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 月度考勤。对应表 monthly_attendance。
 */
@Data
@TableName("monthly_attendance")
public class MonthlyAttendance {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 考勤编号 */
    private String attendanceNo;

    /** 实习档案ID */
    private Long applicationId;

    /** 学生ID */
    private Long studentId;

    /** 学生姓名 */
    private String studentName;

    /** 企业 */
    private String companyName;

    /** 月份 yyyy-MM */
    private String month;

    /** 应出勤 */
    private Integer shouldDays;

    /** 实出勤 */
    private Integer actualDays;

    /** 迟到次数 */
    private Integer lateCount;

    /** 请假天数 */
    private Integer leaveDays;

    /** 备注 */
    private String remark;

    /** 确认状态 */
    private String confirmStatus;

    /** 企业导师 */
    private String mentorName;

    /** 创建时间 */
    private LocalDateTime createTime;

}
