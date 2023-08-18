module ApplicationHelper
  def default_meta_tags
    {
      site: 'そろそろ決め代',
      title: 'なかなか決まらない友だちとの予定決めを促してくれるLINEbot',
      reverse: true,
      charset: 'utf-8',
      description: 'そろそろあの予定を決めませんか？',
      keywords: 'LINEbot、予定調整',
      canonical: request.original_url,
      separator: '|',
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: 'website',
        url: request.original_url,
        image: image_url('ogp.png'),
        local: 'ja-JP',
      },
      twitter: {
        card: 'summary_large_image',
        image: image_url('ogp.png'),
      }
    }
  end
end
