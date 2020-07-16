class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  
  def self.from_omniauth(auth)
    sns = SnsCredential.where(provider: auth.provider, uid: auth.uid).first_or_create
    binding.pry
    # sns認証したことがあればアソシエーションで取得
    # 無ければemailでユーザー検索して取得orビルド(保存はしない)
    user = sns.user || User.where(email: auth.info.email).first_or_initialize(
      nickname: auth.info.name,
      email: auth.info.email
    )
    # userが登録済みの場合はそのままログインの処理へ行くので、ここでsnsのuser_idを更新しておく
    if user.persisted?
      sns.user = user
      sns.save
    end
    user
  end

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:facebook, :google_oauth2]
         
  validates :nickname, :family_name, :first_name, :family_name_kana, :first_name_kana, :birthday ,presence: true
  validates :family_name, :first_name, format: { with: /\A[ぁ-んァ-ン一-龥]+\z/ }
  validates :family_name_kana, :first_name_kana, format: { with: /\A[ぁ-んー－]+\z/ }
  validates_uniqueness_of :email, case_sensitive: false
  
  has_one :send_destination
  has_many :products
  has_many :sns_credentials
end
