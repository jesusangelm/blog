class CommentsController < ApplicationController
  before_action :search_comment, only: [ :create, :destroy ]

  def create
    @comment = @post.comments.create(comment_params)

    redirect_to post_path(@post)
  end

  def destroy
    @comment = @post.comments.find(params[:id])

    @comment.destroy

    redirect_to post_path(@post)
  end

  private

  def search_comment
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:name, :body)
  end
end
