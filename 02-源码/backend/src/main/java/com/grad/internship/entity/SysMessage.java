package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 站内消息。对应表 sys_message。
 */
@Data
@TableName("sys_message")
public class SysMessage {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 标题 */
    private String title;

    /** 内容 */
    private String content;

    /** 类型：待审批/即将超时/已退回/待验收/处理完成 */
    private String msgType;

    /** 业务编号 */
    private String bizNo;

    /** 详情跳转地址 */
    private String linkUrl;

    /** 接收人ID */
    private Long receiverId;

    /** 是否已读 */
    private Integer isRead;

    /** 创建时间 */
    private LocalDateTime createTime;
}
