/*
Copyright © 2012 The Pennsylvania State University

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/


//= require jquery
//= require jquery_ujs
//= require blacklight/blacklight
//= require sufia
//= require batch_edit
//= require scholarsphere_fileupload
//= require transfers
//= require hydra/batch_select
//= require hydra_collections

function modal_collection_list(action, event){
  if(action == 'open'){
    $(".collection-list-container").css("visibility", "visible");
  }
  else if(action == 'close'){
    $(".collection-list-container").css("visibility", "hidden");
  }

  event.preventDefault();
}

