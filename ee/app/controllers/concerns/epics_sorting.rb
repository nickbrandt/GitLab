module EpicsSorting
  def set_epics_sorting
    if current_user
      set_sort_order_from_user_preference
    else
      set_sort_order_from_cookie
    end
  end

  def set_sort_order_from_user_preference
    return params[:sort] unless current_user

    user_preference = current_user.user_preference

    sort_param = params[:sort]
    sort_param ||= user_preference.epics_sort

    if user_preference.epics_sort != sort_param
      user_preference.update(epics_sort: sort_param)
    end

    params[:sort] = sort_param
  end
end
