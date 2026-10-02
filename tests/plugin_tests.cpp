#include "zml_plugin.h"
#include "fixture.hpp"
#include <Windows.h>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
namespace {
ZmlLuaTransform transform{}; void* transformData{}; int registrations{}, writes{}, logs{};
std::string result;
void check(bool v) {if(!v) throw std::runtime_error("Plugin assertion failed");}
int registerTransform(void*,const char* module,ZmlLuaTransform fn,void* data) {
    check(std::string(module)=="UI/Panels/UIDPanel/UIDPanelCtrl");
    transform=fn;transformData=data;++registrations;return 1;
}
void log(void*,const char*) {++logs;}
void sink(void*,const char* bytes,size_t len) {++writes;result.assign(bytes,len);}
}
int main(int argc,char** argv) {
    HMODULE dll{};
    try {
        check(argc==2);
        const auto path=std::filesystem::absolute(argv[1]);
        dll=LoadLibraryW(path.c_str());check(dll!=nullptr);
        const auto entry=reinterpret_cast<ZmlPluginEntry>(GetProcAddress(dll,"ZML_PluginV1"));check(entry!=nullptr);
        const auto* plugin=entry();check(plugin && plugin->size==sizeof(ZmlPlugin) && plugin->abi==1);
        check(std::string(plugin->id)=="hud-fields" && plugin->start(nullptr)==0);
        auto directory=path.parent_path().u8string();
        const auto* dir=reinterpret_cast<const char*>(directory.c_str());
        ZmlHost host{sizeof(ZmlHost),1,nullptr,dir,dir,log,registerTransform};
        auto invalid=host;invalid.abi=2;check(plugin->start(&invalid)==0 && registrations==0);
        invalid=host;invalid.mod_directory="nonexistent";check(plugin->start(&invalid)==0 && registrations==0);
        check(plugin->start(&host)==1 && registrations==1 && transform);
        auto source=fixture();check(transform(transformData,source.data(),source.size(),sink,nullptr)==1 && writes==1);
        check(result.find("local _zmlHudFields")!=result.npos && result.find("return H")!=result.npos);
        auto patched=result;check(transform(transformData,patched.data(),patched.size(),sink,nullptr)==0 && writes==1 && logs==1);
        check(transform(transformData,"broken",6,sink,nullptr)==0 && writes==1 && logs==2);
        FreeLibrary(dll);dll=nullptr;
        std::cout<<"PASS: actual DLL export/ABI/start/registration/sink/fail-closed\n";
    } catch(const std::exception& e) {if(dll)FreeLibrary(dll);std::cerr<<e.what()<<'\n';return 1;}
}
