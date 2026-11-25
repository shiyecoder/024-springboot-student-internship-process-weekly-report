package com.grad.internship.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.grad.internship.entity.MonthlyAttendance;
import org.apache.ibatis.annotations.Mapper;

/** 月度考勤 Mapper。 */
@Mapper
public interface MonthlyAttendanceMapper extends BaseMapper<MonthlyAttendance> {
}
