% convert frame labels to EP map labels
% updated by Zhanning Gao 09/10/2017 --- All for MT&G ---
subset_all = [{'val'}, {'test'}];
for  i = 1:2% 'val' or 'test'
    subset = subset_all{i};
    tau = 2;
    
    % EPmap path
    %EPPath = '/data3_alpha/datasets/TH14/EP-TSN/EP_E48W7Dim128_onInit_incep5a';
    
    % video info path
    video_info_path = '../data';
    
    % load video info
    load(fullfile(video_info_path, ['vid_info_' subset '.mat']));
    
    % load EP data
    load(fullfile(EPPath,['TRUE', subset, '.mat']));
    
    num_vid = length(PIQL);
    num_class = 21;
    
    EPmaps = [];
    
    for i_vid = 1:num_vid
        
        c_PIQL = PIQL{i_vid};
        
        f_all = c_PIQL.frames;
        
        E = c_PIQL.E;
        W = c_PIQL.W;
        
        vid_list = c_PIQL.vid_list;
        num_list = size(vid_list,1);
        
        EPmap_all = [];
        mask_all = [];
        
        for i_list = 1:num_list
            
            EPmap = zeros(E,E,num_class);
            
            for i_info = 1:length(vid_info)
                if strcmp(c_PIQL.name,vid_info(i_info).name)
                    f_label = vid_info(i_info).labels(vid_list(i_list,1):vid_list(i_list,2));
                    break;
                end
            end
            
            for i_c = 1:num_class
                ind_c = find(f_label==i_c);
                if isempty(ind_c)
                    continue;
                end
                
                c_ql = c_PIQL.ql(:,:,ind_c);
                
                Kmap = zeros(E,E);
                Wmap = sum(c_ql,3);
                Kmap(Wmap>tau)=1;
                mask = zeros((W-1)*2+1);
                mask(W:end,W:end)=1;
                Kmap = circconv2(Kmap,mask,W-1,[E,E]);
                Kmap(Kmap>0)=1;
                
                EPmap(:,:,i_c) = Kmap;
                
            end
            
            c_last = sum(EPmap(:,:,1:end-1),3);
            c_last(c_last>0)=1;
            
            mask = sum(EPmap,3);
            mask(mask>0)=1;
            
            EPmap(:,:,end) = xor(ones(size(c_last)), c_last);
            
            % normalization
            EPmap = EPmap./repmat(sum(EPmap,3),[1,1,num_class]);
            EPmap_all{i_list} = EPmap;
            mask_all{i_list} = mask;
        end
        
        EPmaps(i_vid).EPmap = EPmap_all;
        EPmaps(i_vid).mask = mask_all;
        EPmaps(i_vid).E = E;
        EPmaps(i_vid).W = W;
        
    end
    
    save([EPPath '/EPmaps_info_' subset '.mat'], 'EPmaps');
    
end