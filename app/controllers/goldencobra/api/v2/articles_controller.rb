# encoding: utf-8

module Goldencobra
  module Api
    module V2
      class ArticlesController < ActionController::Base
        skip_before_filter :verify_authenticity_token

        respond_to :json

        # /api/v2/articles/search[.json]
        # ---------------------------------------------------------------------------------------
        def search

          # Check if we have an argument.
          unless params[:q]
            render status: 200, json: { :status => 200 }
            return
          end

          # Check if the query string contains something.
          if params[:q].length == 0
            render status: 200, json: { :status => 200 }
          else
            # Search and return the result array.
            render status: 200, json: Goldencobra::Article.simple_search(
                ActionController::Base.helpers.sanitize(params[:q])
            ).to_json
          end
        end


        # /api/v2/articles/create[.json]
        # ---------------------------------------------------------------------------------------
        def create
          # Check if a user is currently logged in.
          unless current_user
            render status: 403, json: { :status => 403 }
            return
          end

          # Check if we do have an article passed by the parameters.
          unless params[:article]
            render status: 400, json: { :status => 400, :error => "article data missing" }
            return
          end

          #check if an external referee is passed by the parameters
          unless params[:referee_id]
            render status: 400, json: { :status => 400, :error => "referee_id missing"  }
            return
          end

          #check if Article already exists by comparing external referee and current user of caller
          existing_articles = Goldencobra::Article.where(:creator_id => current_user.id, :external_referee_id => params[:referee_id])
          if existing_articles.any?
            render status: 423, json: { :status => 423, :error => "article already exists", :id => existing_articles.first.id  }
            return
          end

          # Try to save the article
          response = create_article(params[:article])
          if response.id.present?
            render status: 200, json: { :status => 200, :id => response.id }
          else
            render status: 500, json: { :status => 500, :error => response.errors, :id => nil }
          end

        end


        def update
          unless current_user
            render status: 403, json: { :status => 403 }
            return
          end

          # Check if we do have an article passed by the parameters.
          unless params[:article]
            render status: 400, json: { :status => 400, :error => "article data missing" }
            return
          end

          #check if an external referee is passed by the parameters
          unless params[:referee_id]
            render status: 400, json: { :status => 400, :error => "referee_id missing"  }
            return
          end

          #check if Article already exists by comparing external referee and current user of caller
          existing_articles = Goldencobra::Article.where(:creator_id => current_user.id, :external_referee_id => params[:referee_id])
          if existing_articles.blank?
            render status: 423, json: { :status => 423, :error => "article not found", :id => nil  }
            return
          end

          # Try to save the article
          response = update_article(params[:article])
          if response.id.present?
            render status: 200, json: { :status => 200, :id => response.id }
          else
            render status: 500, json: { :status => 500, :error => response.errors, :id => nil }
          end
        end


        protected

        # Creates an article from the given article array.
        # ---------------------------------------------------------------------------------------
        def create_article(article_param)

          # Input validation
          return nil unless article_param
          return nil unless params[:article]
          return nil unless current_user
          return nil unless params[:referee_id]

          # Create a new article
          new_article = Goldencobra::Article.new(params[:article])
          new_article.creator_id = current_user.id

          if params[:article][:article_type]
            new_article.article_type = params[:article][:article_type]
          else
            new_article.article_type = 'Default Show'
          end

          if params[:author].present? && params[:author][:lastname].present?
            author = Goldencobra::Author.find_or_create_by_lastname(params[:author][:lastname])
            new_article.author = author
          end

          #Set externel Referee
          new_article.external_referee_id = params[:referee_id]
          new_article.external_referee_ip = request.env['REMOTE_ADDR']

          # Try to save the article
          new_article.save
          return new_article
        end


        def update_article(article_param)
          # Input validation
          return nil unless article_param
          return nil unless params[:article]
          return nil unless current_user
          return nil unless params[:referee_id]

          # Get existing article
          article = Goldencobra::Article.where(:creator_id => current_user.id).find_by_external_referee_id(params[:referee_id])

          if params[:author].present? && params[:author][:lastname].present?
            author = Goldencobra::Author.find_or_create_by_lastname(params[:author][:lastname])
            article.author = author
            article.save
          end

          # Update existing article
          article.update_attributes(params[:article])

          # Try to save the article
          return article

        end


      end
    end
  end
end
