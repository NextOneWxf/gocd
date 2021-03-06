##########################################################################
# Copyright 2018 ThoughtWorks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

class AnalyticsController < ApplicationController
  include AuthenticationHelper

  layout 'single_page_app', only: [:index]

  before_action :check_admin_user_and_401
  before_action :check_permissions, only: [:show]

  def index
    @view_title = 'Analytics'
    @supported_dashboard_metrics = default_plugin_info_finder.allPluginInfos(PluginConstants.ANALYTICS_EXTENSION).inject({})do |memo, plugin|
      key = plugin.getDescriptor().id()
      memo[key] = supported_analytics_hash(plugin.getCapabilities().supportedDashboardAnalytics()) if plugin.getCapabilities().supportsDashboardAnalytics()
      memo
    end
  end

  def show
    render json: analytics_extension.getAnalytics(params[:plugin_id], params[:type], params[:id], request.query_parameters).toMap().to_h
  rescue => e
    render_plugin_error e
  end

  private

  def supported_analytics_hash supported_analytics
    supported_analytics.map do |s|
      {type: s.getType(), id: s.getId(), title: s.getTitle()}
    end

  end

  def check_permissions
    check_user_can_see_pipeline if params[:type] == 'pipeline'
  end

  def render_plugin_error e
    log_java_error(e)
    render :text => "Error generating analytics from plugin - #{params[:plugin_id]}", status: 500
  end

  def log_java_error(e)
    cause = e.getMessage()
    stack_trace = com.google.common.base.Throwables.getStackTraceAsString(e)

    Rails.logger.error "#{cause}:\n\n#{stack_trace}"
  end
end
