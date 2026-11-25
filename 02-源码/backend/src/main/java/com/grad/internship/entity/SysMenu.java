package com.grad.internship.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 菜单。对应表 sys_menu。
 */
@Data
@TableName("sys_menu")
public class SysMenu {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 父菜单ID，0为顶级 */
    private Long parentId;

    /** 菜单名称 */
    private String menuName;

    /** 前端路由 */
    private String path;

    /** 图标标识 */
    private String icon;

    /** 类型：目录/菜单/按钮 */
    private String menuType;

    /** 排序号 */
    private Integer sortNo;

    /** 是否可见 */
    private Integer visible;

    /** 创建时间 */
    private LocalDateTime createTime;
}
