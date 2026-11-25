package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 组织（养护单位/管理部门）。对应表 sys_org。
 */
@Data
@TableName("sys_org")
public class SysOrg {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 组织名称 */
    private String orgName;

    /** 类型：主管单位/养护单位 */
    private String orgType;

    /** 上级组织ID */
    private Long parentId;

    /** 联系人 */
    private String contact;

    /** 电话 */
    private String phone;

    /** 创建时间 */
    private LocalDateTime createTime;
}
