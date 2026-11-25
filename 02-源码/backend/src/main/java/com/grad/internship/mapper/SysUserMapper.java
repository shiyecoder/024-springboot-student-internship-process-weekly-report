package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.SysUser;
import org.apache.ibatis.annotations.Mapper;

/** 系统用户 数据访问。 */
@Mapper
public interface SysUserMapper extends BaseMapper<SysUser> {
}
