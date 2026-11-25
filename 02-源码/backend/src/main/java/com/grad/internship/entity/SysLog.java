package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 操作日志。对应表 sys_log。
 */
@Data
@TableName("sys_log")
public class SysLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 操作人ID */
    private Long userId;

    /** 操作人姓名 */
    private String userName;

    /** 动作描述 */
    private String action;

    /** 请求方法 */
    private String method;

    /** 请求参数摘要 */
    private String params;

    /** 来源IP */
    private String ip;

    /** 耗时毫秒 */
    private Long costMs;

    /** 操作时间 */
    private LocalDateTime createTime;
}
