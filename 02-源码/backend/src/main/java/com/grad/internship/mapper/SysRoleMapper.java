package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.SysRole;
import org.apache.ibatis.annotations.Mapper;

/** 角色 数据访问。 */
@Mapper
public interface SysRoleMapper extends BaseMapper<SysRole> {
}
